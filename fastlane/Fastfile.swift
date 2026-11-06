// This file contains the fastlane.tools configuration
// You can find the documentation at https://docs.fastlane.tools
//
// For a list of all available actions, check out
//
//     https://docs.fastlane.tools/actions
//

import Foundation

class Fastfile: LaneFile {

    // MARK: - Version
    
    private struct Version: CustomStringConvertible, Equatable {

        enum BumpType {
            case major
            case minor
            case patch
        }
        
        private static let pattern = /^(?<major>\d+)(?:\.(?<minor>\d+))?(?:\.(?<patch>\d+))?$/
        
        var major: Int
        var minor: Int
        var patch: Int
        
        init(major: Int, minor: Int, patch: Int = 0) {
            self.major = major
            self.minor = minor
            self.patch = patch
        }
        
        init?(string: String) {
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard let match = trimmed.wholeMatch(of: Self.pattern),
                  let majorValue = Int(String(match.output.major)) else {
                return nil
            }
            
            major = majorValue
            minor = match.output.minor.flatMap { Int(String($0)) } ?? 0
            patch = match.output.patch.flatMap { Int(String($0)) } ?? 0
        }
        
        mutating func bump(_ bumpType: BumpType) {
            switch bumpType {
            case .major:
                major += 1
                minor = 0
                patch = 0
            case .minor:
                minor += 1
                patch = 0
            case .patch:
                patch += 1
            }
        }
        
        var description: String {
            if patch == 0 {
                "\(major).\(minor)"
            } else {
                "\(major).\(minor).\(patch)"
            }
        }
    }
    
    // MARK: - Configuration

    private struct ScreenshotRuntime: Decodable {

        let platform: String
        let version: String
        let build: String
        let profiles: [ScreenshotProfile]
    }

    private struct ScreenshotProfile: Decodable {

        let name: String
        let device: String
    }

    private let bundleIdentifier = "org.jellyfin.swiftfin"
    private let xcodeProject = "Swiftfin.xcodeproj"
    private let sourcePackagesPath = "build/SourcePackages"

    private var statusBarTime: String {
        let noon = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: .now) ?? .now
        let formatter = ISO8601DateFormatter()

        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = .current

        return formatter.string(from: noon)
    }

    // MARK: - testFlightLane
    
    func testFlightLane(withOptions options: [String: String]?) {
        
        let requiredKeys = [
            "keyID",
            "issuerID",
            "scheme",
            "codeSign64",
            "profileName64"
        ]

        guard let options else {
            fail("missing options")
        }
        
        let validation = validatedRequiredOptions(options, requiredKeys: requiredKeys)

        if !validation.missingKeys.isEmpty {
            fail("missing or empty options: \(validation.missingKeys.joined(separator: ", "))")
        }
        
        let requiredOptions = validation.values

        guard
              let keyID = requiredOptions["keyID"],
              let issuerID = requiredOptions["issuerID"],
              let scheme = requiredOptions["scheme"],
              let codeSign64 = requiredOptions["codeSign64"],
              let profileName64 = requiredOptions["profileName64"] else {
            fail("internal validation error")
        }

        guard let keyContents = ProcessInfo.processInfo.environment["FL_KEY_CONTENTS"]?.trimOption() else {
            fail("missing or empty environment variable: FL_KEY_CONTENTS")
        }

        let normalizedKeyContents = keyContents.components(separatedBy: .whitespacesAndNewlines).joined()

        let sdk = sdk(forScheme: scheme)
        let appPlatform = appPlatform(forSDK: sdk)
        
        guard let decodedCodeSignIdentity = decodeBase64(encoded: codeSign64) else {
            fail("code sign identity not valid base 64")
        }
        
        guard let profileName = decodeBase64(encoded: profileName64) else {
            fail("profile name not valid base 64")
        }
        
        if let xcodeVersion = options["xcodeVersion"]?.trimOption() {
            xcodes(version: xcodeVersion)
        }
        
        appStoreConnectApiKey(
            keyId: keyID,
            issuerId: .userDefined(issuerID),
            keyContent: .userDefined(normalizedKeyContents),
            isKeyContentBase64: true,
            duration: 1200,
            inHouse: false
        )
        
        updateCodeSigningSettings(
            path: xcodeProject,
            useAutomaticSigning: false,
            codeSignIdentity: .userDefined(decodedCodeSignIdentity),
            profileName: .userDefined(profileName),
            bundleIdentifier: .userDefined(bundleIdentifier)
        )
        
        let resolvedVersion: String

        if let providedVersion = options["version"]?.trimOption() {
            guard let version = Version(string: providedVersion) else {
                fail("invalid provided version '\(providedVersion)'")
            }
            
            resolvedVersion = providedVersion
            
            incrementVersionNumber(
                versionNumber: .userDefined(version.description),
                xcodeproj: .userDefined(xcodeProject)
            )
        } else {
            
            appStoreBuildNumber(
                initialBuildNumber: "1",
                appIdentifier: bundleIdentifier,
                live: .userDefined(true),
                platform: appPlatform
            )

            let liveVersion: String? = laneContextValue(for: "LATEST_VERSION")
            
            latestTestflightBuildNumber(
                appIdentifier: bundleIdentifier,
                platform: appPlatform,
                initialBuildNumber: 1
            )
            
            let testFlightVersion: String? = laneContextValue(for: "LATEST_TESTFLIGHT_VERSION")
            
            guard let testFlightVersion else {
                fail("missing testflight version")
            }
            
            guard var version = Version(string: testFlightVersion) else {
                fail("invalid version '\(testFlightVersion)'")
            }
            
            if let liveVersion, Version(string: liveVersion) == version {
                version.bump(.minor)
            }
            
            resolvedVersion = version.description
            
            incrementVersionNumber(
                versionNumber: .userDefined(version.description),
                xcodeproj: .userDefined(xcodeProject)
            )
        }
        
        let resolvedBuild: String

        if let build = options["build"]?.trimOption() {
            resolvedBuild = build
            
            incrementBuildNumber(
                buildNumber: .userDefined(build),
                xcodeproj: .userDefined(xcodeProject)
            )
        } else {
            let testFlightBuild: Int = laneContextValue(for: "LATEST_TESTFLIGHT_BUILD_NUMBER") ?? 0
            resolvedBuild = "\(testFlightBuild + 1)"

            incrementBuildNumber(
                buildNumber: .userDefined(resolvedBuild),
                xcodeproj: .userDefined(xcodeProject)
            )
        }

        let outputDirectory = "fastlane/build/\(sanitizedName(for: scheme))"
        try? FileManager.default.removeItem(atPath: outputDirectory)

        buildApp(
            scheme: .userDefined(scheme),
            outputDirectory: outputDirectory,
            outputName: .userDefined("\(sanitizedName(for: scheme)).ipa"),
            skipArchive: .userDefined(false),
            sdk: .userDefined(sdk),
            xcargs: .userDefined("-skipMacroValidation"),
            buildTimingSummary: true,
            skipProfileDetection: false,
            clonedSourcePackagesPath: .userDefined(sourcePackagesPath),
            disablePackageAutomaticUpdates: true
        )

        var changelog: String?

        if let changelogFile = options["changelogFile"]?.trimOption() {
            changelog = (try? String(contentsOfFile: changelogFile, encoding: .utf8))?
                .trimOption()
        }
        
        let ipa = "\(outputDirectory)/\(sanitizedName(for: scheme)).ipa"
        guard FileManager.default.fileExists(atPath: ipa) else {
            fail("couldn't find ipa file")
        }

        if options["skipUpload"]?.trimOption()?.lowercased() == "true" {
            puts(message: "Built \(scheme) \(resolvedVersion) (\(resolvedBuild)). Skipping TestFlight upload.")
            return
        }
        
        puts(message: "Uploading \(scheme) \(resolvedVersion) (\(resolvedBuild))")

        uploadToTestflight(
            appPlatform: .userDefined(appPlatform),
            ipa: .userDefined(ipa),
            changelog: .userDefined(changelog),
            appVersion: .userDefined(resolvedVersion),
            buildNumber: .userDefined(resolvedBuild)
        )
    }
    
    // MARK: - buildLane
    
    func buildLane(withOptions options: [String: String]?) {

        guard let options,
              let scheme = options["scheme"]?.trimOption() else {
            fail("missing or incorrect options")
        }

        if let xcodeVersion = options["xcodeVersion"] {
            xcodes(version: xcodeVersion)
        }

        buildApp(
            scheme: .userDefined(scheme),
            outputDirectory: "fastlane/build",
            skipPackageIpa: .userDefined(true),
            skipArchive: .userDefined(false),
            skipCodesigning: .userDefined(true),
            archivePath: .userDefined("fastlane/build/\(sanitizedName(for: scheme)).xcarchive"),
            sdk: .userDefined(sdk(forScheme: scheme)),
            xcargs: .userDefined("-skipMacroValidation"),
            buildTimingSummary: true,
            skipProfileDetection: true,
            clonedSourcePackagesPath: .userDefined(sourcePackagesPath),
            disablePackageAutomaticUpdates: true
        )
    }

    // MARK: - screenshotsLane

    func screenshotsLane(withOptions options: [String: String]?) {
        let options = options ?? [:]

        if let option = options.keys.first(where: {
            let key = $0.lowercased()

            return key.hasSuffix("device") || key.hasSuffix("version") || key == "runtime"
        }) {
            fail("The '\(option)' option cannot override a screenshot profile. Device and runtime are pinned in Profiles.json.")
        }

        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let tools = root.appendingPathComponent("Tools/Screenshots")
        let profilesFile = tools.appendingPathComponent("Profiles.json")

        guard let runtimes = try? JSONDecoder().decode([ScreenshotRuntime].self, from: Data(contentsOf: profilesFile)) else {
            fail("Unable to read screenshot profiles from \(profilesFile.path)")
        }

        let profiles = runtimes.flatMap { runtime in runtime.profiles.map { (runtime: runtime, profile: $0) } }
        let selected = options["platform"]?.trimOption()?.lowercased()
        let targets = profiles.filter { selected == nil || selected == $0.profile.name.lowercased() }

        guard !targets.isEmpty else {
            fail("Unknown screenshot platform. Choose \(profiles.map(\.profile.name).joined(separator: ", ")).")
        }

        let isRawOnly = options["process"]?.trimOption()?.lowercased() == "false"

        guard isInstalled("oxipng") else { fail("Install oxipng with 'brew install oxipng' before capturing.") }

        if targets.contains(where: { $0.profile.name == "iPhoneDuo" }), !isInstalled("hinge") {
            fail("For the Duo, install the hinge CLI with 'brew install artemnovichkov/tap/hinge'.")
        }

        let destinations = targets.map { runtime, profile in
            (runtime, profile.name, screenshotSimulator(profile.device, runtime: runtime))
        }

        for (runtime, profile, device) in destinations {
            let captureDirectory = root.appendingPathComponent("build/Screenshots/Capture/\(profile)")
            let outputDirectory = tools.appendingPathComponent("Output/\(profile)")
            let scheme = runtime.platform == "tvOS" ? "Swiftfin tvOS" : "Swiftfin"
            let testTarget = "Swiftfin \(runtime.platform) Screenshots"
            let isDuo = profile == "iPhoneDuo"
            let duo = Process()

            if isDuo {
                duo.executableURL = URL(fileURLWithPath: "/bin/bash")
                duo.arguments = [tools.appendingPathComponent("CaptureDuo.sh").path, device]

                do {
                    try duo.run()
                } catch {
                    fail(error.localizedDescription)
                }
            }

            defer {
                if duo.isRunning {
                    duo.terminate()
                }
            }

            captureIosScreenshots(
                project: .userDefined(xcodeProject),
                xcargs: .userDefined("-skipMacroValidation -collect-test-diagnostics never -parallel-testing-enabled NO"),
                devices: .userDefined([device]),
                languages: ["en-US"],
                launchArguments: [isDuo ? "-captureDuo" : ""],
                outputDirectory: captureDirectory.path,
                iosVersion: .userDefined(runtime.version),
                skipOpenSummary: .userDefined(true),
                clearPreviousScreenshots: .userDefined(true),
                eraseSimulator: .userDefined(true),
                overrideStatusBar: .userDefined(runtime.platform != "tvOS"),
                overrideStatusBarArguments: .userDefined(
                    "--time \(statusBarTime) --dataNetwork wifi --wifiMode active --wifiBars 3 --cellularMode active --operatorName '' --cellularBars 4 --batteryState charged --batteryLevel 100"
                ),
                darkMode: .userDefined(true),
                appIdentifier: .userDefined(bundleIdentifier),
                scheme: .userDefined(scheme),
                numberOfRetries: 0,
                stopAfterFirstError: .userDefined(true),
                derivedDataPath: .userDefined("build/Screenshots"),
                clonedSourcePackagesPath: .userDefined(sourcePackagesPath),
                disablePackageAutomaticUpdates: .userDefined(true),
                onlyTesting: ["\(testTarget)/ScreenshotTests/testScreenshots"],
                xcodebuildFormatter: isInstalled("xcbeautify") ? "xcbeautify" : ""
            )

            let processor = ["swift", tools.appendingPathComponent("ProcessScreenshots.swift").path, profile]
            let rawDirectory = tools.appendingPathComponent("Raw/\(profile)")

            runScreenshotTool(processor + [captureDirectory.path, rawDirectory.path, "--raw-only"])

            if !isRawOnly {
                runScreenshotTool(processor + [rawDirectory.path, outputDirectory.path])
            }
        }
    }

    private func screenshotSimulator(_ deviceType: String, runtime: ScreenshotRuntime) -> String {
        struct DeviceType: Decodable {

            let name: String
            let identifier: String
        }

        struct Runtime: Decodable {

            let identifier: String
            let platform: String
            let version: String
            let buildversion: String
            let isAvailable: Bool
            let supportedDeviceTypes: [DeviceType]
        }

        struct Device: Decodable {

            let name: String
            let deviceTypeIdentifier: String?
            let isAvailable: Bool
        }

        struct Simulators: Decodable {

            let runtimes: [Runtime]
            let devices: [String: [Device]]
        }

        let identifier = "com.apple.CoreSimulator.SimDeviceType." + deviceType
        let json = sh(command: "xcrun simctl list -j", log: false)

        guard let list = try? JSONDecoder().decode(Simulators.self, from: Data(json.utf8)) else {
            fail("Unable to read the installed simulators.")
        }

        let os = "\(runtime.platform) \(runtime.version)"

        guard let installed = list.runtimes.first(where: {
            $0.isAvailable
                && $0.platform == runtime.platform
                && $0.version == runtime.version
                && $0.buildversion == runtime.build
        }), let model = installed.supportedDeviceTypes.first(where: { $0.identifier == identifier })?.name else {
            fail(
                "Capture requires \(deviceType) on \(os) (\(runtime.build)). "
                    + "Install the runtime with 'xcodebuild -downloadPlatform \(runtime.platform) -buildVersion \(runtime.build)'."
            )
        }

        // Snapshot and hinge both look up simulators by name. Snapshot recognizes tvOS by the "Apple TV" prefix.
        let name = runtime.platform == "tvOS" ? "\(model) - Store Screenshots - \(os)" : "Store Screenshots - \(model) - \(os)"
        let named = list.devices.values.joined().filter { $0.isAvailable && $0.name == name }

        if named.isEmpty {
            runScreenshotTool(["xcrun", "simctl", "create", name, identifier, installed.identifier])
        } else if named.count != 1
            || list.devices[installed.identifier]?.contains(where: {
                $0.isAvailable && $0.name == name && $0.deviceTypeIdentifier == identifier
            }) != true
        {
            fail("Another simulator already uses the capture name '\(name)'.")
        }

        return name
    }

    private func runScreenshotTool(_ arguments: [String]) {
        let command = arguments.map { "'" + $0.replacingOccurrences(of: "'", with: "'\\''") + "'" }.joined(separator: " ")

        sh(command: command, log: true)
    }

    private func isInstalled(_ executable: String) -> Bool {
        (ProcessInfo.processInfo.environment["PATH"] ?? "")
            .split(separator: ":")
            .contains { FileManager.default.isExecutableFile(atPath: "\($0)/\(executable)") }
    }

    private func decodeBase64(encoded: String) -> String? {
        guard let data = Data(base64Encoded: encoded),
              let decoded = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return decoded
    }

    private func fail(_ message: String) -> Never {
        puts(message: "ERROR: \(message)")
        exit(1)
    }

    private func laneContextValue<T>(for key: String, as type: T.Type = T.self) -> T? {
        laneContext()[key] as? T
    }

    private func validatedRequiredOptions(
        _ options: [String: String],
        requiredKeys: [String]
    ) -> (values: [String: String], missingKeys: [String]) {
        var validatedOptions = [String: String]()
        var missingKeys = [String]()
        
        for key in requiredKeys {
            guard let value = options[key]?.trimOption() else {
                missingKeys.append(key)
                continue
            }
            
            validatedOptions[key] = value
        }
        
        return (validatedOptions, missingKeys)
    }

    private func sdk(forScheme scheme: String) -> String {
        if scheme.localizedCaseInsensitiveContains("tvos") {
            return "appletvos"
        }

        return "iphoneos"
    }

    private func appPlatform(forSDK sdk: String) -> String {
        let normalizedSDK = sdk.lowercased()

        if normalizedSDK.contains("appletv") || normalizedSDK.contains("tvos") {
            return "appletvos"
        }

        return "ios"
    }

    private func sanitizedName(for scheme: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let sanitizedScalars = scheme.unicodeScalars.map { scalar in
            allowed.contains(scalar) ? Character(scalar) : "-"
        }

        return String(sanitizedScalars)
    }
}

extension String {
    
    /// Trim whitespaces and newlines, which may
    /// accidentally be present in GitHub secrets.
    ///
    /// Returns nil if the trimmed result is empty.
    func trimOption() -> String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
