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
    
    // MARK: Utilities
    
    private func decodeBase64(encoded: String) -> String? {
        guard let data = Data(base64Encoded: encoded),
              let decoded = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return decoded
    }
}
