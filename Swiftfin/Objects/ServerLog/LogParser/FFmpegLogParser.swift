//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

/// Parse server FFmpeg logs into section-grouped `ServerLogEntry` records.
struct FFmpegLogParser: LogParser<ServerLogEntry> {

    let encoding: String.Encoding = .utf8
    let delimiter: String = "\n"

    private var current: FFmpegLogSection?
    private var firstLine: String?
    private var buffer: [String] = []
    private var nextID: Int = 0
    private var deferredProgress: DeferredSection?

    private struct DeferredSection {
        let section: FFmpegLogSection
        let firstLine: String?
        let buffer: [String]
    }

    mutating func consume(chunk line: String) -> [ServerLogEntry] {
        var output: [ServerLogEntry] = []

        // Blank lines separate sections.
        if line.isEmpty {
            return output
        }

        let next = FFmpegLogSection.classify(line: line, currentSection: current)

        if let next, next != current {
            // Progress → summary: defer flushing the progress section so we can
            // pin its end frame using the summary's trailing `frame=…Lsize=…` line.
            if case .progress = current, next == .summary, let currentSection = current {
                deferredProgress = DeferredSection(
                    section: currentSection,
                    firstLine: firstLine,
                    buffer: buffer
                )
                current = next
                firstLine = line
                buffer = [line]
                return output
            }

            var endFrame: Int?
            if case let .progress(nextFrame) = next {
                endFrame = max(0, nextFrame - 1)
            }
            if let entry = flushCurrent(endFrame: endFrame) {
                output.append(entry)
            }
            current = next
            firstLine = line
            buffer = [line]
        } else if current != nil {
            buffer.append(line)
        } else {
            current = .other
            firstLine = line
            buffer = [line]
        }

        return output
    }

    mutating func flush() -> [ServerLogEntry] {
        var output: [ServerLogEntry] = []

        // Emit the deferred final progress, using the summary buffer's trailing
        // frame= line as its end bound.
        if let deferred = deferredProgress {
            let trailingFrame = buffer
                .compactMap(FFmpegLogSection.parseFrameNumber)
                .last
            let endFrame = trailingFrame.map { max(0, $0 - 1) }
            output.append(
                makeEntry(
                    section: deferred.section,
                    firstLine: deferred.firstLine,
                    buffer: deferred.buffer,
                    endFrame: endFrame
                )
            )
            deferredProgress = nil
        }

        if let entry = flushCurrent(endFrame: nil) {
            output.append(entry)
        }
        return output
    }

    private mutating func flushCurrent(endFrame: Int?) -> ServerLogEntry? {
        defer {
            buffer.removeAll(keepingCapacity: true)
            firstLine = nil
        }

        guard let current, buffer.isNotEmpty else { return nil }

        return makeEntry(
            section: current,
            firstLine: firstLine,
            buffer: buffer,
            endFrame: endFrame
        )
    }

    private mutating func makeEntry(
        section: FFmpegLogSection,
        firstLine: String?,
        buffer: [String],
        endFrame: Int?
    ) -> ServerLogEntry {
        let entry = ServerLogEntry(
            id: nextID,
            timestamp: nil,
            type: section.entryType,
            source: section.sourceName(firstLine: firstLine, endFrame: endFrame),
            message: section.format(lines: buffer)
        )
        nextID += 1
        return entry
    }
}

// MARK: - Section

private enum FFmpegLogSection: Equatable {

    case parameters
    case command
    case version
    case configuration
    case hardwareInit(type: String)
    case input
    case streamMapping
    case output
    case progress(frame: Int)
    case summary
    case other

    static func classify(line: String, currentSection: FFmpegLogSection?) -> FFmpegLogSection? {
        guard let first = line.first else { return nil }

        // Once we're in the transcoding phase, only `frame=` (new progress) and
        // `[out#` (summary) cause transitions. Everything else — segment events,
        // codec messages, warnings — continues whatever section is open.
        if isTranscodingSection(currentSection) {
            if line.hasPrefix("[out#") {
                return .summary
            }
            if line.hasPrefix("frame=") {
                if currentSection == .summary {
                    return nil
                }
                let frame = parseFrameNumber(line) ?? 0
                return .progress(frame: frame)
            }
            return nil
        }

        // JSON parameters at the top of the log.
        if first == "{" {
            return .parameters
        }

        // Indented lines may transition from `.version` into `.configuration`.
        if first.isWhitespace {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("configuration:") {
                return .configuration
            }
            if currentSection == .version,
               trimmed.hasPrefix("libav") || trimmed.hasPrefix("libsw") || trimmed.hasPrefix("libpost")
            {
                return .configuration
            }
            return nil
        }

        if line.hasPrefix("ffmpeg version") {
            return .version
        }
        if line.hasPrefix("ffmpeg ") || line.hasPrefix("/") {
            return .command
        }
        if let hwType = hardwareType(for: line) {
            return .hardwareInit(type: hwType)
        }
        if line.hasPrefix("Input #") {
            return .input
        }
        if line.hasPrefix("Stream mapping:") {
            return .streamMapping
        }
        if line.hasPrefix("Press [q]") {
            return nil
        }
        if line.hasPrefix("Output #") {
            return .output
        }

        return .other
    }

    private static func isTranscodingSection(_ section: FFmpegLogSection?) -> Bool {
        switch section {
        case .output, .progress, .summary:
            true
        default:
            false
        }
    }

    fileprivate static func parseFrameNumber(_ line: String) -> Int? {
        guard line.hasPrefix("frame=") else { return nil }
        let after = line.dropFirst("frame=".count).drop(while: { $0 == " " })
        let digits = after.prefix { $0.isNumber }
        return Int(digits)
    }

    /// Detects hardware-acceleration init lines and returns the type name.
    /// Returns `nil` if the line isn't a known HWA init line.
    private static func hardwareType(for line: String) -> String? {
        if line.hasPrefix("libva ") || line.hasPrefix("libva info") {
            return "VA-API"
        }
        if line.hasPrefix("Cuda") || line.hasPrefix("[CUDA") {
            return "CUDA"
        }
        if line.hasPrefix("[NVENC") || line.hasPrefix("[NVDEC") {
            return "NVENC"
        }
        if line.hasPrefix("[QSV") {
            return "QSV"
        }
        if line.hasPrefix("[AMF") {
            return "AMF"
        }
        if line.hasPrefix("[VideoToolbox") {
            return "VideoToolbox"
        }
        if line.hasPrefix("[Vulkan") {
            return "Vulkan"
        }
        return nil
    }

    var entryType: ServerLogEntryType? {
        switch self {
        case .parameters,
             .command,
             .version,
             .configuration,
             .hardwareInit,
             .input,
             .streamMapping,
             .output,
             .summary:
            .info
        case .progress:
            .debug
        case .other:
            nil
        }
    }

    func sourceName(firstLine: String?, endFrame: Int? = nil) -> String {
        switch self {
        case .parameters:
            "FFmpeg Parameters"
        case .command:
            "FFmpeg Command"
        case .version:
            "FFmpeg Version"
        case .configuration:
            "FFmpeg Configuration"
        case let .hardwareInit(type):
            "FFmpeg \(type)"
        case .input:
            "FFmpeg Input \(extractIndex(firstLine: firstLine, prefix: "Input "))"
        case .streamMapping:
            "Stream Mapping"
        case .output:
            "FFmpeg Output \(extractIndex(firstLine: firstLine, prefix: "Output "))"
        case let .progress(frame):
            if let endFrame, endFrame > frame {
                "FFmpeg Progress \(frame)-\(endFrame)"
            } else {
                "FFmpeg Progress \(frame)"
            }
        case .summary:
            "FFmpeg Summary"
        case .other:
            "Other"
        }
    }

    func format(lines: [String]) -> String {
        switch self {
        case .parameters:
            Self.formatParameters(lines)
        case .command:
            Self.formatCommand(lines)
        case .version:
            lines.map { $0.trimmingCharacters(in: .whitespaces) }.joined(separator: "\n")
        case .configuration:
            Self.formatConfiguration(lines)
        case .hardwareInit, .input, .streamMapping, .output, .progress, .summary, .other:
            lines.joined(separator: "\n")
        }
    }

    private func extractIndex(firstLine: String?, prefix: String) -> String {
        guard let firstLine, firstLine.hasPrefix(prefix) else { return "" }
        let after = firstLine.dropFirst(prefix.count)
        return String(after.prefix { !$0.isWhitespace && $0 != "," && $0 != ":" })
    }

    // MARK: - Formatters

    private static func formatParameters(_ lines: [String]) -> String {
        let json = lines.joined()
        guard let data = json.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return lines.joined(separator: "\n")
        }
        return object.keys
            .sorted()
            .map { "\($0): \(stringify(object[$0]))" }
            .joined(separator: "\n")
    }

    private static func formatCommand(_ lines: [String]) -> String {
        let combined = lines.joined(separator: " ")
        let tokens = shellSplit(combined)
        guard let path = tokens.first else { return combined }

        var output: [String] = ["Path: \(path)"]
        var index = 1
        while index < tokens.count {
            let token = tokens[index]
            if isFlagLike(token) {
                let name = String(token.dropFirst())
                if index + 1 < tokens.count, !isFlagLike(tokens[index + 1]) {
                    output.append("\(name): \(tokens[index + 1])")
                    index += 2
                } else {
                    output.append(name)
                    index += 1
                }
            } else {
                index += 1
            }
        }
        return output.joined(separator: "\n")
    }

    private static func formatConfiguration(_ lines: [String]) -> String {
        var output: [String] = []
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("configuration:") {
                let flagsString = trimmed
                    .dropFirst("configuration:".count)
                    .trimmingCharacters(in: .whitespaces)
                for token in flagsString.split(separator: " ") {
                    let raw = String(token)
                    guard raw.hasPrefix("--") else { continue }
                    let stripped = raw.dropFirst(2)
                    if let eq = stripped.firstIndex(of: "=") {
                        let name = String(stripped[..<eq])
                        let value = String(stripped[stripped.index(after: eq)...])
                        output.append("\(name): \(value)")
                    } else {
                        output.append(String(stripped))
                    }
                }
            } else {
                output.append(trimmed)
            }
        }
        return output.joined(separator: "\n")
    }

    // MARK: - Helpers

    private static func stringify(_ value: Any?) -> String {
        guard let value, !(value is NSNull) else { return "null" }
        if let s = value as? String { return s }
        if let n = value as? NSNumber { return n.stringValue }
        if let data = try? JSONSerialization.data(withJSONObject: value, options: []),
           let json = String(data: data, encoding: .utf8)
        {
            return json
        }
        return "\(value)"
    }

    private static func isFlagLike(_ token: String) -> Bool {
        guard token.count >= 2, token.first == "-" else { return false }
        return token.dropFirst().first?.isLetter == true
    }

    private static func shellSplit(_ string: String) -> [String] {
        var tokens: [String] = []
        var current = ""
        var inDouble = false
        var inSingle = false
        var escaped = false

        for char in string {
            if escaped {
                current.append(char)
                escaped = false
                continue
            }
            if char == "\\", !inSingle {
                escaped = true
                continue
            }
            if char == "\"", !inSingle {
                inDouble.toggle()
                continue
            }
            if char == "'", !inDouble {
                inSingle.toggle()
                continue
            }
            if char.isWhitespace, !inDouble, !inSingle {
                if !current.isEmpty {
                    tokens.append(current)
                    current = ""
                }
                continue
            }
            current.append(char)
        }
        if !current.isEmpty {
            tokens.append(current)
        }
        return tokens
    }
}
