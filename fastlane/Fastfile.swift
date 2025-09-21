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
    
    // TODO: verify tvOS
    /// - Important: Remember to pass in options from GitHub Actions
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
        
        if let branch = options["branch"] {
            sh(
                command: "git checkout \(branch)",
                log: .userDefined(true)
            ) { errorMessage in
                puts(message: "ERROR: \(errorMessage)")
            }
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
        
        if let version = options["version"] {
            incrementVersionNumber(
                versionNumber: .userDefined(version),
                xcodeproj: .userDefined(swiftfinXcodeProject)
            )
        }
        
        if let build = options["build"] {
            incrementBuildNumber(
                buildNumber: .userDefined(build),
                xcodeproj: .userDefined(swiftfinXcodeProject)
            )
        } else {
            incrementBuildNumber(
                xcodeproj: .userDefined(swiftfinXcodeProject)
            )
        }
        
        buildApp(
            scheme: .userDefined(scheme),
            skipArchive: .userDefined(false),
            xcargs: .userDefined("-skipMacroValidation"),
            skipProfileDetection: false
        )
        
        uploadToTestflight(
            ipa: "Swiftfin iOS.ipa"
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
    
    /// Trim the option value from whitespaces and newlines, which may
    /// accidentally be present in GitHub secrets.
    func trimOption() -> String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
