//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

// Path to the English localization file.
let localizationFile = "./Translations/en.lproj/Localizable.strings"

// Directories to scan for Swift files.
let directoriesToScan = ["./Shared", "./Swiftfin", "./Swiftfin tvOS"]

// Files skipped during hardcoded-string scanning.
let excludedFiles: Set<String> = [
    "./Shared/Strings/Strings.swift",
    "./Shared/Views/SettingsView/DebugSettingsView.swift",
]

// --dry previews proposed changes.
// --replace applies proposed changes.
let isDryRun = CommandLine.arguments.contains("--dry")
let isReplace = CommandLine.arguments.contains("--replace")

guard !(isReplace && isDryRun) else {
    print("Cannot use --dry and --replace together.")
    exit(1)
}

// SwiftUI objects / structs that contain user-facing text.
enum ObjectName: String, CaseIterable {
    case text = "Text"
    case button = "Button"
    case label = "Label"
    case toggle = "Toggle"
    case picker = "Picker"
    case textField = "TextField"
    case secureField = "SecureField"
    case section = "Section"
    case stepper = "Stepper"
    case menu = "Menu"
    case link = "Link"
    case navigationLink = "NavigationLink"
}

// SwiftUI modifiers that contain user-facing text.
enum ModifierName: String, CaseIterable {
    case navigationTitle
    case navigationBarTitle
    case navigationSubtitle
    case navigationBarBackButtonTitle
    case help
    case alert
    case confirmationDialog
}

// Resource schemes that should be treated literally.
enum URLPrefix: String, CaseIterable {
    case http = "http://"
    case https = "https://"
    case file = "file://"
    case mailto = "mailto:"
    case tel = "tel:"
    case sms = "sms:"
    case swiftfin = "swiftfin://"
}

// Body of a Swift string literal.
// - Also looks for `\(...)` interpolation.
let stringLiteralBody = #"(?:[^"\\]|\\\([^)]*\)|\\.)*"#

// Matches object calls like `Text("...")`.
// - Looks for positions 1 & 2.
let objectRegex = try! NSRegularExpression(
    pattern: #"(?<!\w)(\#(ObjectName.allCases.map(\.rawValue).joined(separator: "|")))\(\s*"(\#(stringLiteralBody))""#
)

// Matches modifier calls like `.navigationTitle("...")`.
// - Looks for positions 1 & 2.
let modifierRegex = try! NSRegularExpression(
    pattern: #"\.(\#(ModifierName.allCases.map(\.rawValue).joined(separator: "|")))\(\s*"(\#(stringLiteralBody))""#
)

// Matches lines like "key" = "value"; in Localizable.strings.
let localizationRegex = #/^\"(?<key>[^\"]+)\"\s*=\s*\"(?<value>(?:[^\"\\]|\\.)*)\";\s*$/#

// Attempt to load the localization file's content.
guard let localizationContent = try? String(contentsOfFile: localizationFile, encoding: .utf16) else {
    print("Unable to read localization file at \(localizationFile)")
    exit(1)
}

// Parse existing entries into a dictionary of [key: value].
var localizationEntries = [String: String]()
for line in localizationContent.components(separatedBy: .newlines) {
    if let match = line.firstMatch(of: localizationRegex) {
        localizationEntries[String(match.output.key)] = String(match.output.value)
    }
}

// Attempts to find the right L10n.key for a found string.
var valueToKey = [String: String]()
for (key, value) in localizationEntries {
    if let current = valueToKey[value], current.count <= key.count { continue }
    valueToKey[value] = key
}

// MARK: - Scan Swift files

/// What did we find in the Swift files?
struct Finding {
    let file: String
    let line: Int
    let kind: String
    let text: String
    let literalRange: NSRange
}

var findings = [Finding]()

// Exclude strings that are unlikely to be human-facing text:
// - Too short
// - Pure punctuation/numbers
// - URLs
// - Purely interpolation (e.g. `"\(a)/\(b)"`)
func isLikelyNotUserText(_ s: String) -> Bool {
    let trimmed = s.trimmingCharacters(in: .whitespaces)
    if trimmed.isEmpty || trimmed.count <= 2 { return true }

    // Check for numbers only text.
    let digitsAndDots = CharacterSet(charactersIn: "0123456789.-")
    if trimmed.unicodeScalars.allSatisfy({ digitsAndDots.contains($0) }) { return true }

    if URLPrefix.allCases.contains(where: { trimmed.hasPrefix($0.rawValue) }) { return true }

    // Strip `\(...)` interpolations to check for any remaining letters.
    // - `"\(a) / \(b)"` strips to `" / "` — no letters, so not user text.
    var stripped = trimmed
    while let open = stripped.range(of: #"\("#),
          let close = stripped.range(of: ")", range: open.upperBound ..< stripped.endIndex)
    {
        stripped.removeSubrange(open.lowerBound ..< close.upperBound)
    }
    return !stripped.unicodeScalars.contains { CharacterSet.letters.contains($0) }
}

// Scan a Swift file for hardcoded user-facing strings.
func scanFile(_ filePath: String) {
    guard let content = try? String(contentsOfFile: filePath, encoding: .utf8) else { return }

    for (index, line) in content.components(separatedBy: .newlines).enumerated() {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("//") || trimmed.hasPrefix("*") || trimmed.hasPrefix("/*") { continue }

        let ns = line as NSString
        let lineRange = NSRange(location: 0, length: ns.length)

        for regex in [objectRegex, modifierRegex] {
            for match in regex.matches(in: line, range: lineRange) {
                let kind = ns.substring(with: match.range(at: 1))
                let contentRange = match.range(at: 2)
                let text = ns.substring(with: contentRange)

                // Remove words that are most likely intentional.
                // - This will result in false negatives but get us *close*.
                if isLikelyNotUserText(text) { continue }

                // Skip call strings opted out via the `.doNotLocalize` modifier.
                let afterEnd = match.range.location + match.range.length
                if afterEnd < ns.length {
                    let rest = ns.substring(from: afterEnd)
                    let marker = ".doNotLocalize"
                    if rest.hasPrefix(marker) {
                        let next = rest.dropFirst(marker.count).first
                        if next == nil || !(next!.isLetter || next!.isNumber || next == "_") {
                            continue
                        }
                    }
                }

                // Widen the capture range by one on each side to cover the surrounding quotes.
                // - This goes from Word to "Word" to get the full blcok.
                let literalRange = NSRange(
                    location: contentRange.location - 1,
                    length: contentRange.length + 2
                )

                findings.append(Finding(
                    file: filePath,
                    line: index + 1,
                    kind: kind,
                    text: text,
                    literalRange: literalRange
                ))
            }
        }
    }
}

// Scan a directory recursively for Swift files.
func scanDirectory(_ path: String) {
    let fileManager = FileManager.default
    guard let enumerator = fileManager.enumerator(atPath: path) else { return }

    for case let file as String in enumerator {
        let filePath = "\(path)/\(file)"

        // Skip the excluded file.
        if excludedFiles.contains(filePath) { continue }

        // Process only Swift files.
        if file.hasSuffix(".swift") {
            scanFile(filePath)
        }
    }
}

// Scan all specified directories.
for directory in directoriesToScan {
    scanDirectory(directory)
}

// Exit if no matches were found.
if findings.isEmpty {
    print("No hardcoded user-facing strings found.")
    exit(0)
}

// MARK: - Propose L10n keys

// Converts a "String Of Words" to a sentence case "String of words".
func sentenceCase(_ input: String) -> String {
    var words = input.components(separatedBy: " ")
    var seenFirstWord = false

    for count in 0 ..< words.count {
        let word = words[count]

        let leading = word.prefix(while: { !$0.isLetter })
        let rest = word.dropFirst(leading.count)

        let core = rest.prefix(while: {
            $0.isLetter
                || $0 == "'"
                || $0 == "-"
                || $0 == "’"
        })

        let trailing = rest.dropFirst(core.count)
        let coreString = String(core)

        let transformed: String = if coreString.isEmpty {
            ""
        } else if coreString.count >= 2,
                  coreString.allSatisfy({ $0.isUppercase || !$0.isLetter }),
                  coreString.contains(where: \.isUppercase)
        {
            coreString
        } else if !seenFirstWord {
            coreString.prefix(1).uppercased() + coreString.dropFirst().lowercased()
        } else {
            coreString.lowercased()
        }

        if !coreString.isEmpty { seenFirstWord = true }
        words[count] = String(leading) + transformed + String(trailing)
    }

    return words.joined(separator: " ")
}

// Create a camelCase key from a hard-coded string value.
// - Preserve ALL-CAPS values as acronyms.
func makeKey(from input: String) -> String {
    var text = input

    // Drop `\(...)` interpolations before word-splitting to variables aren't in the key.
    while let open = text.range(of: #"\("#),
          let close = text.range(of: ")", range: open.upperBound ..< text.endIndex)
    {
        text.removeSubrange(open.lowerBound ..< close.upperBound)
    }

    text = text.replacingOccurrences(of: "\\", with: " slash ")
    text = text.replacingOccurrences(of: "/", with: " slash ")
    text = text.replacingOccurrences(of: "&", with: " and ")
    text = text.replacingOccurrences(of: "%", with: " percent ")

    let allowed = CharacterSet.alphanumerics.union(.whitespaces)
    let scalars = text.unicodeScalars.filter {
        allowed.contains($0)
    }

    // Caps word count at 4 so long sentences don't produce huge key names.
    // - The runner should step in a manually make the key for longer strings.
    let words = String(String.UnicodeScalarView(scalars))
        .split(separator: " ")
        .filter { !$0.isEmpty }
        .prefix(4)

    guard let first = words.first else { return "unnamed" }

    let head = first.lowercased()

    let tail = words.dropFirst().map { word -> String in
        if word.count >= 2, word.allSatisfy({ $0.isUppercase || $0.isNumber }) {
            return String(word)
        }
        return word.prefix(1).uppercased() + word.dropFirst().lowercased()
    }

    return ([head] + tail).joined()
}

/// What are we going to do about our findings?
struct Proposal {
    let finding: Finding
    let key: String
    let value: String
    let isNew: Bool
}

var proposals = [Proposal]()
var interpolated = [Finding]()

for finding in findings {
    // Skip interpolated strings since thes need manual `L10n.fooX(...)` setup.
    if finding.text.contains("\\(") {
        interpolated.append(finding)
        continue
    }

    let sentenced = sentenceCase(finding.text)

    // Reuse an existing key when the value exactly matches.
    if let existingKey = valueToKey[finding.text] ?? valueToKey[sentenced] {
        proposals.append(Proposal(
            finding: finding,
            key: existingKey,
            value: localizationEntries[existingKey] ?? sentenced,
            isNew: false
        ))
        continue
    }

    proposals.append(Proposal(
        finding: finding,
        key: makeKey(from: sentenced),
        value: sentenced,
        isNew: true
    ))
}

// Detect conflicts before writing as a sanity check:
// - A new key collides with an existing key.
// - Two proposals create the same key with different values.
var conflicts = [String]()

for proposal in proposals where proposal.isNew {
    if let existing = localizationEntries[proposal.key], existing != proposal.value {
        conflicts.append("Key '\(proposal.key)' already exists as \"\(existing)\" but proposal wants \"\(proposal.value)\"")
    }
}

for (key, group) in Dictionary(grouping: proposals.filter(\.isNew), by: \.key) {
    let distinctValues = Set(group.map(\.value))
    if distinctValues.count > 1 {
        conflicts.append("Multiple proposals map to key '\(key)': " + distinctValues.sorted().map { "\"\($0)\"" }.joined(separator: ", "))
    }
}

// MARK: - Report

// Print proposals grouped by kind > string > call sites.
func printGroupedProposals(_ items: [Proposal], showKey: Bool) {
    let byKind = Dictionary(grouping: items, by: \.finding.kind)

    for (kind, group) in byKind.sorted(by: { $0.key < $1.key }) {
        print("  \(kind)")

        let byValue = Dictionary(grouping: group, by: \.value)

        for (value, matches) in byValue.sorted(by: { $0.key < $1.key }) {
            if showKey {
                print("    - \"\(value)\" → L10n.\(matches[0].key)")
            } else {
                print("    - \"\(value)\"")
            }

            let sites = matches.map(\.finding).sorted {
                ($0.file, $0.line) < ($1.file, $1.line)
            }

            for site in sites {
                print("      - \(site.file):\(site.line)")
            }
        }
        print()
    }
}

// Print interpolated strings grouped by kind > string > call sites.
func printInterpolated(_ items: [Finding]) {
    let byKind = Dictionary(grouping: items, by: \.kind)

    for (kind, group) in byKind.sorted(by: { $0.key < $1.key }) {
        print("  \(kind)")

        let byText = Dictionary(grouping: group, by: \.text)

        for (text, matches) in byText.sorted(by: { $0.key < $1.key }) {
            print("    - \"\(text)\"")

            let sites = matches.sorted {
                ($0.file, $0.line) < ($1.file, $1.line)
            }

            for site in sites {
                print("      - \(site.file):\(site.line)")
            }
        }
        print()
    }
}

// Map out hard-coded strings and what actions should be done.
let reuses = proposals.filter { !$0.isNew }
let creates = proposals.filter(\.isNew)

if !isReplace {
    if !reuses.isEmpty {
        print("Found \(reuses.count) site(s) that can reuse existing L10n keys:\n")
        printGroupedProposals(reuses, showKey: true)
    }

    if !creates.isEmpty {
        print("Found \(creates.count) site(s) that need new L10n keys:\n")
        printGroupedProposals(creates, showKey: isDryRun)
    }

    if !interpolated.isEmpty {
        print("Found \(interpolated.count) interpolated site(s) needing manual handling:\n")
        printInterpolated(interpolated)
    }

    if isDryRun, !conflicts.isEmpty {
        print("Found \(conflicts.count) conflict(s):\n")
        for c in conflicts {
            print("  - \(c)")
        }
        print()
    }

    if isDryRun {
        print("DRY RUN: No changes were written. Run with --replace to apply them.")
        exit(1)
    }

    print("Found \(findings.count) total hardcoded string(s).")

    print(
        "\nRun 'swift Scripts/Translations/FindHardCodedStrings.swift --dry' to preview L10n changes, or --replace to apply them."
    )

    print("Opt out by using the '.doNotLocalize' modifer on the non-localized strings or by adding the string to ProperNouns.swift.")

    exit(1)
}

// MARK: - Apply replacements

if !conflicts.isEmpty {
    print("Found \(conflicts.count) conflict(s) — resolve before running --replace:\n")

    for conflict in conflicts {
        print("  - \(conflict)")
    }

    exit(3)
}

// Rewrite each Swift file with the new keys instead of hard-coded values.
let byFile = Dictionary(grouping: proposals, by: \.finding.file)

for (filePath, items) in byFile {
    guard let content = try? String(contentsOfFile: filePath, encoding: .utf8) else {
        print("Warning: could not read \(filePath), skipping")
        continue
    }

    var lines = content.components(separatedBy: .newlines)

    for (lineNumber, onLine) in Dictionary(grouping: items, by: \.finding.line) {
        var line = lines[lineNumber - 1]

        let ordered = onLine.sorted {
            $0.finding.literalRange.location > $1.finding.literalRange.location
        }

        for text in ordered {
            line = (line as NSString).replacingCharacters(in: text.finding.literalRange, with: "L10n.\(text.key)")
        }

        lines[lineNumber - 1] = line
    }

    do {
        try lines.joined(separator: "\n").write(toFile: filePath, atomically: true, encoding: .utf8)
    } catch {
        print("Error: failed to write \(filePath): \(error)")
        exit(2)
    }
}

var updatedEntries = localizationEntries
let newKeyCount = Set(proposals.filter(\.isNew).map(\.key)).count

for proposal in proposals where proposal.isNew {
    updatedEntries[proposal.key] = proposal.value
}

let sortedKeys = updatedEntries.keys.sorted {
    $0.localizedCaseInsensitiveCompare($1) == .orderedAscending
}

let updatedStrings = sortedKeys
    .map { "/// \(updatedEntries[$0]!)\n\"\($0)\" = \"\(updatedEntries[$0]!)\";" }
    .joined(separator: "\n\n")

do {
    try updatedStrings.write(toFile: localizationFile, atomically: true, encoding: .utf16)
} catch {
    print("Error: failed to write \(localizationFile): \(error)")
    exit(2)
}

print("Replaced \(proposals.count) site(s) across \(byFile.count) file(s).")

print("Added \(newKeyCount) new key(s) to \(localizationFile).")

if !interpolated.isEmpty {
    print("Skipped \(interpolated.count) interpolated string(s). You will need to handle these manually!")
}

print("\nRun 'swiftgen config run' or build the Swiftfin to regenerate Strings.swift.")
exit(0)
