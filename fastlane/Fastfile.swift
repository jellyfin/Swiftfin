// This file contains the fastlane.tools configuration
// You can find the documentation at https://docs.fastlane.tools
//
// For a list of all available actions, check out
//
//     https://docs.fastlane.tools/actions
//

import Foundation

class Fastfile: LaneFile {
    
    private let swiftfinBundleIdentifier = "org.jellyfin.swiftfin"
    private let swiftfinXcodeProject = "Swiftfin.xcodeproj"
    
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
            path: swiftfinXcodeProject,
            useAutomaticSigning: false,
            codeSignIdentity: .userDefined(decodedCodeSignIdentity),
            profileName: .userDefined(profileName),
            bundleIdentifier: .userDefined(swiftfinBundleIdentifier)
        )

        if let providedVersion = options["version"]?.trimOption() {
            guard let version = Version(string: providedVersion) else {
                fail("invalid provided version '\(providedVersion)'")
            }
            
            incrementVersionNumber(
                versionNumber: .userDefined(version.description)
            )
        } else {
            
            appStoreBuildNumber(
                initialBuildNumber: "1",
                appIdentifier: swiftfinBundleIdentifier,
                live: .userDefined(true)
            )

            let liveVersion: String? = laneContextValue(for: "LATEST_VERSION")
            
            latestTestflightBuildNumber(
                appIdentifier: swiftfinBundleIdentifier,
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
            
            incrementVersionNumber(
                versionNumber: .userDefined(version.description)
            )
        }

        if let build = options["build"]?.trimOption() {
            incrementBuildNumber(
                buildNumber: .userDefined(build),
                xcodeproj: .userDefined(swiftfinXcodeProject)
            )
        } else {
            let testFlightBuild: Int = laneContextValue(for: "LATEST_TESTFLIGHT_BUILD_NUMBER") ?? 0

            incrementBuildNumber(
                buildNumber: .userDefined("\(testFlightBuild + 1)"),
            )
        }

        buildApp(
            scheme: .userDefined(scheme),
            skipArchive: .userDefined(false),
            xcargs: .userDefined("-skipMacroValidation"),
            skipProfileDetection: false
        )

        var changelog: String?

        if let changelogFile = options["changelogFile"]?.trimOption() {
            changelog = (try? String(contentsOfFile: changelogFile, encoding: .utf8))?
                .trimOption()
        }
        
        guard let ipa = sh(command: "find . -name '*.ipa' -print -quit").trimOption() else {
            fail("couldn't find ipa file")
        }

        uploadToTestflight(
            ipa: .userDefined(ipa),
            changelog: .userDefined(changelog)
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
            exportMethod: .userDefined("development"),
            skipArchive: .userDefined(true),
            skipCodesigning: .userDefined(true),
            xcargs: .userDefined("-skipMacroValidation"),
            skipProfileDetection: true
        )
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
