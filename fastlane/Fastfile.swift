// This file contains the fastlane.tools configuration
// You can find the documentation at https://docs.fastlane.tools
//
// For a list of all available actions, check out
//
//     https://docs.fastlane.tools/actions
//

import Foundation

class Fastfile: LaneFile {
    
    private let bundleIdentifier = "org.jellyfin.swiftfin"
    private let xcodeProject = "Swiftfin.xcodeproj"
    private let sourcePackagesPath = "build/SourcePackages"
    
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
    
    // MARK: - testFlightLane
    
    func testFlightLane(withOptions options: [String: String]?) {
        
        let requiredKeys = [
            "keyID",
            "issuerID",
            "keyContents",
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
              let keyContents = requiredOptions["keyContents"],
              let scheme = requiredOptions["scheme"],
              let codeSign64 = requiredOptions["codeSign64"],
              let profileName64 = requiredOptions["profileName64"] else {
            fail("internal validation error")
        }

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
            keyContent: .userDefined(keyContents),
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
            resolvedBuild = "\(testFlightBuild)"

            incrementBuildNumber(
                buildNumber: .userDefined("\(testFlightBuild + 1)"),
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
            skipProfileDetection: true,
            clonedSourcePackagesPath: .userDefined(sourcePackagesPath),
            disablePackageAutomaticUpdates: true
        )
    }

    // MARK: - screenshotsLane

    private enum ScreenshotPlatform: String, CaseIterable {
        case iOS
        case iPadOS
        case tvOS

        var scheme: String {
            switch self {
            case .iOS, .iPadOS:
                "Swiftfin iOS Screenshots"
            case .tvOS:
                "Swiftfin tvOS Screenshots"
            }
        }

        var deviceOption: String {
            "\(rawValue.lowercased())Device"
        }

        var defaultDeviceType: String {
            switch self {
            case .iOS:
                "iPhone-17-Pro"
            case .iPadOS:
                "iPad-Pro-13-inch-M5-12GB"
            case .tvOS:
                "Apple-TV-4K-3rd-generation-4K"
            }
        }

        var runtimePlatform: String {
            switch self {
            case .iOS, .iPadOS:
                "iOS"
            case .tvOS:
                "tvOS"
            }
        }
    }

    private struct DeviceTypeList: Decodable {
        struct DeviceType: Decodable {
            let identifier: String
            let name: String
        }

        let devicetypes: [DeviceType]
    }

    private struct RuntimeList: Decodable {
        struct Runtime: Decodable {
            let identifier: String
            let platform: String?
            let version: String
            let isAvailable: Bool
        }

        let runtimes: [Runtime]
    }

    private struct DeviceList: Decodable {
        struct Device: Decodable {
            let name: String
            let deviceTypeIdentifier: String?
        }

        let devices: [String: [Device]]
    }

    private let repositoryDirectory = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()

    func screenshotsLane(withOptions options: [String: String]?) {

        let platforms: [ScreenshotPlatform]

        if let platform = options?["platform"]?.trimOption() {
            guard let screenshotPlatform = ScreenshotPlatform.allCases.first(where: {
                $0.rawValue.lowercased() == platform.lowercased()
            }) else {
                fail("invalid platform '\(platform)', expected ios, ipados, or tvos")
            }

            platforms = [screenshotPlatform]
        } else {
            platforms = ScreenshotPlatform.allCases
        }

        let shouldProcess = options?["process"]?.trimOption().map { $0.lowercased() != "false" } ?? true

        let launchArguments = [
            ("server", "ScreenshotServer"),
            ("username", "ScreenshotUsername"),
            ("password", "ScreenshotPassword"),
        ]
        .compactMap { option, argument in
            options?[option]?.trimOption().map { "-\(argument) \($0)" }
        }
        .joined(separator: " ")

        for platform in platforms {
            let captureDirectory = repositoryDirectory.appendingPathComponent("build/Screenshots/Capture/\(platform.rawValue)")
            let outputDirectory = repositoryDirectory.appendingPathComponent("Documentation/Screenshots/\(platform.rawValue)")
            let captionsDirectory = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Library/Caches/tools.fastlane/Captions")

            let device = simulator(
                deviceType: options?[platform.deviceOption]?.trimOption() ?? platform.defaultDeviceType,
                runtimePlatform: platform.runtimePlatform
            )

            try? FileManager.default.removeItem(at: captionsDirectory)

            captureIosScreenshots(
                project: .userDefined(xcodeProject),
                xcargs: .userDefined("-skipMacroValidation -collect-test-diagnostics never"),
                devices: .userDefined([device]),
                languages: ["en-US"],
                launchArguments: [launchArguments],
                outputDirectory: captureDirectory.path,
                skipOpenSummary: .userDefined(true),
                clearPreviousScreenshots: .userDefined(true),
                eraseSimulator: .userDefined(true),
                overrideStatusBar: .userDefined(platform != .tvOS),
                overrideStatusBarArguments: .userDefined(
                    "--time \(statusBarTime) --dataNetwork wifi --wifiMode active --wifiBars 3 --cellularMode active --operatorName '' --cellularBars 4 --batteryState charged --batteryLevel 100"
                ),
                darkMode: .userDefined(true),
                appIdentifier: .userDefined(bundleIdentifier),
                scheme: .userDefined(platform.scheme),
                numberOfRetries: 0,
                stopAfterFirstError: .userDefined(true),
                derivedDataPath: .userDefined("build/Screenshots"),
                clonedSourcePackagesPath: .userDefined(sourcePackagesPath),
                disablePackageAutomaticUpdates: .userDefined(true),
                xcodebuildFormatter: isInstalled("xcbeautify") ? "xcbeautify" : ""
            )

            let languages = collectScreenshots(device: device, from: captureDirectory, to: outputDirectory)

            guard shouldProcess else { continue }

            let script = repositoryDirectory.appendingPathComponent("Scripts/Screenshots/ProcessScreenshots.swift")

            for language in languages {
                sh(command: "swift \"\(script.path)\" \"\(language.path)\" \"\(captionsDirectory.path)\"")
            }
        }
    }

    private func collectScreenshots(device: String, from captureDirectory: URL, to outputDirectory: URL) -> [URL] {
        let fileManager = FileManager.default

        try? fileManager.removeItem(at: outputDirectory)

        let languages = (try? fileManager.contentsOfDirectory(at: captureDirectory, includingPropertiesForKeys: [.isDirectoryKey])) ?? []
        var outputLanguages: [URL] = []

        for language in languages where language.hasDirectoryPath {
            let outputLanguage = outputDirectory.appendingPathComponent(language.lastPathComponent)
            let rawDirectory = outputLanguage.appendingPathComponent("Raw")
            let screenshots = (try? fileManager.contentsOfDirectory(at: language, includingPropertiesForKeys: nil)) ?? []

            try? fileManager.createDirectory(at: rawDirectory, withIntermediateDirectories: true)

            for screenshot in screenshots where screenshot.pathExtension == "png" {
                let name = screenshot.lastPathComponent.replacingOccurrences(of: "\(device)-", with: "")
                try? fileManager.copyItem(at: screenshot, to: rawDirectory.appendingPathComponent(name))
            }

            outputLanguages.append(outputLanguage)
        }

        return outputLanguages
    }

    private func simctlList<T: Decodable>(_ type: T.Type, _ arguments: String) -> T {
        let output = sh(command: "xcrun simctl list -j \(arguments)", log: .userDefined(false))

        guard let list = try? JSONDecoder().decode(T.self, from: Data(output.utf8)) else {
            fail("unable to read simctl \(arguments)")
        }

        return list
    }

    private func simulator(deviceType: String, runtimePlatform: String) -> String {
        let identifier = deviceType.hasPrefix("com.apple") ? deviceType : "com.apple.CoreSimulator.SimDeviceType.\(deviceType)"
        let deviceTypes = simctlList(DeviceTypeList.self, "devicetypes").devicetypes

        guard let type = deviceTypes.first(where: { $0.identifier == identifier }) else {
            let available = deviceTypes.map { $0.identifier.replacingOccurrences(of: "com.apple.CoreSimulator.SimDeviceType.", with: "") }
            fail("simulator type '\(deviceType)' is not installed. Available: \(available.joined(separator: ", "))")
        }

        let devices = simctlList(DeviceList.self, "devices available").devices.values.flatMap { $0 }

        if let existing = devices.first(where: { $0.deviceTypeIdentifier == identifier }) {
            return existing.name
        }

        guard let runtime = simctlList(RuntimeList.self, "runtimes").runtimes
            .filter({ $0.isAvailable && $0.platform == runtimePlatform })
            .max(by: { $0.version.compare($1.version, options: .numeric) == .orderedAscending })
        else {
            fail("no \(runtimePlatform) simulator runtime is installed")
        }

        sh(command: "xcrun simctl create \"\(type.name)\" \(identifier) \(runtime.identifier)")

        return type.name
    }

    private var statusBarTime: String {
        let noon = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: .now) ?? .now
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = .current
        return formatter.string(from: noon)
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
