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
    
    // MARK: TestFlight
    
    func testFlightLane(withOptions options: [String: String]?) {
        
        guard let options,
              let keyID = options["keyID"]?.trimOption(),
              let issuerID = options["issuerID"]?.trimOption(),
              let keyContents = options["keyContents"]?.trimOption(),
              let scheme = options["scheme"]?.trimOption(),
              let codeSign64 = options["codeSign64"]?.trimOption(),
              let profileName64 = options["profileName64"]?.trimOption()
        else {
            puts(message: "ERROR: missing or incorrect options")
            exit(1)
        }
        
        guard let decodedCodeSignIdentity = decodeBase64(encoded: codeSign64) else {
            puts(message: "ERROR: code sign identity not valid base 64")
            exit(1)
        }
        
        guard let profileName = decodeBase64(encoded: profileName64) else {
            puts(message: "ERROR: profile name not valid base 64")
            exit(1)
        }
        
        if let xcodeVersion = options["xcodeVersion"] {
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
        
        appStoreBuildNumber(
            initialBuildNumber: "1",
            appIdentifier: swiftfinBundleIdentifier,
            live: .userDefined(true)
        )
        
        let liveVersion = laneContext()["SharedValues::LATEST_VERSION"] as? String
        
        let testFlightBuild = latestTestflightBuildNumber(
            appIdentifier: swiftfinBundleIdentifier,
            initialBuildNumber: 0
        )
        
        let testFlightVersion = laneContext()["SharedValues::LATEST_TESTFLIGHT_VERSION"] as? String

        if let providedVersion = options["version"] {
            incrementVersionNumber(
                versionNumber: .userDefined(providedVersion)
            )
        } else {
            if liveVersion == testFlightVersion {
                incrementVersionNumber(
                    versionNumber: .userDefined(testFlightVersion)
                )
                
                incrementVersionNumber(
                    bumpType: "minor"
                )
            } else {
                incrementVersionNumber(
                    versionNumber: .userDefined(testFlightVersion)
                )
            }
        }

        if let build = options["build"] {
            incrementBuildNumber(
                buildNumber: .userDefined(build),
                xcodeproj: .userDefined(swiftfinXcodeProject)
            )
        } else {
            incrementBuildNumber(
                buildNumber: .userDefined("\(testFlightBuild + 1)"),
                xcodeproj: .userDefined(swiftfinXcodeProject)
            )
        }

        buildApp(
            scheme: .userDefined(scheme),
            skipArchive: .userDefined(false),
            xcargs: .userDefined("-skipMacroValidation"),
            skipProfileDetection: false
        )

        // Read changelog from temp file if provided
        var changelog: String?

        if let changelogFile = options["changelogFile"]?.trimOption() {
            changelog = (try? String(contentsOfFile: changelogFile, encoding: .utf8))?
                .trimOption()
        }

        uploadToTestflight(
            ipa: .userDefined("Swiftfin"),
            changelog: .userDefined(changelog)
        )
    }
    
    func buildLane(withOptions options: [String: String]?) {
        guard let options,
              let scheme = options["scheme"]?.trimOption() else {
            puts(message: "ERROR: missing or incorrect options")
            exit(1)
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
    
    // MARK: Utilities
    
    private func decodeBase64(encoded: String) -> String? {
        guard let data = Data(base64Encoded: encoded),
              let decoded = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return decoded
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
