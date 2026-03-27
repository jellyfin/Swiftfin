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
        
        let version = options["version"]

        if let version {
            incrementVersionNumber(
                versionNumber: .userDefined(version),
                xcodeproj: .userDefined(swiftfinXcodeProject)
            )
        }

        let build = options["build"]

        if build == "auto" {
            // Query App Store Connect for the latest build number for this version, then increment by 1.
            // First build for a new version starts at 1.
            // Example:
            // - Current release is 1.4. TestFlight would be 1.5 (1)
            // - The next TestFlight would be 1.5 (2)
            guard let version else {
                puts(message: "ERROR: build is 'auto' but no version was provided")
                exit(1)
            }
            let latest = latestTestflightBuildNumber(
                appIdentifier: .userDefined(swiftfinBundleIdentifier),
                version: .userDefined(version)
            )
            let next = latest + 1
            puts(message: "Auto-increment: latest build \(latest) → next build \(next)")
            incrementBuildNumber(
                buildNumber: .userDefined("\(next)"),
                xcodeproj: .userDefined(swiftfinXcodeProject)
            )
        } else if let build {
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

        // Dynamic IPA name based on scheme
        // - Eventually use for iOS & tvOS (& macOS?)
        let ipaName = scheme.contains("tvOS") ? "Swiftfin tvOS.ipa" : "Swiftfin iOS.ipa"
        uploadToTestflight(
            ipa: .userDefined(ipaName)
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
    /// Returns nil if the trimming result is empty or "" so we can `guard` or `if let`
    func trimOption() -> String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
