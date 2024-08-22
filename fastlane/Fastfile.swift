// This file contains the fastlane.tools configuration
// You can find the documentation at https://docs.fastlane.tools
//
// For a list of all available actions, check out
//
//     https://docs.fastlane.tools/actions
//

import Foundation

class Fastfile: LaneFile {
    
    // MARK: tag
    
    func tagLane(withOptions options: [String: String]?) {
        
        guard let options,
                let tag = options["tag"] else {
            puts(message: "ERROR: missing options")
            exit(1)
        }

        guard !gitTagExists(tag: tag) else {
            puts(message: "ERROR: tag \(tag) already exists")
            exit(1)
        }
        
        addGitTag(
            tag: .userDefined(tag),
            commit: .userDefined(options["commit"])
        )
        
        pushGitTags(
            force: true
        )
    }
    
    // MARK: draft release
    
    func draftReleaseLane(withOptions options: [String: String]?) {
        
        guard let options,
                let repository = options["repository"],
                let apiToken = options["apiToken"],
                let tag = options["tag"],
                let name64 = options["name64"] else {
            puts(message: "ERROR: missing options")
            exit(1)
        }
        
        guard let name = decodeBase64(encoded: name64) else {
            puts(message: "ERROR: name not valid base 64")
            exit(1)
        }
        
        setGithubRelease(
            repositoryName: repository,
            apiToken: .userDefined(apiToken),
            tagName: tag,
            name: .userDefined(name),
            isDraft: true,
            isGenerateReleaseNotes: true
        )
    }
    
    // MARK: TestFlight
    
    // TODO: verify tvOS
    func testFlightLane(withOptions options: [String: String]?) {
        
        guard let options,
              let keyID = options["keyID"],
              let issuerID = options["issuerID"],
              let keyContents = options["keyContents"],
              let scheme = options["scheme"],
              let codeSign64 = options["codeSign64"],
              let profileName64 = options["profileName64"]
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
            path: "Swiftfin.xcodeproj",
            useAutomaticSigning: false,
            codeSignIdentity: .userDefined(decodedCodeSignIdentity),
            profileName: .userDefined(profileName)
        )
        
        if let version = options["version"] {
            incrementVersionNumber(
                versionNumber: .userDefined(version),
                xcodeproj: "Swiftfin.xcodeproj"
            )
        }
        
        if let build = options["build"] {
            incrementBuildNumber(
                buildNumber: .userDefined(build),
                xcodeproj: "Swiftfin.xcodeproj"
            )
        } else {
            incrementBuildNumber(
                xcodeproj: "Swiftfin.xcodeproj"
            )
        }
        
        buildApp(
            scheme: .userDefined(scheme),
            skipArchive: .userDefined(false),
            skipProfileDetection: false
        )
        
        uploadToTestflight(
            ipa: "Swiftfin iOS.ipa"
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
