//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Alamofire
import Foundation
import JellyfinAPI

class DownloadManager {
    
    static func download(item: BaseItemDto, fileName: String) {
        guard let itemFileURL = item.getDownloadURL() else { return }

        let destination: DownloadRequest.Destination = { _, _ in
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsURL.appendingPathComponent("\(item.id ?? "none")/\(fileName)")
            
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        AF.download(itemFileURL, to: destination)
            .downloadProgress { progress in
                print("Download progress: \(progress.fractionCompleted)")
            }
            .responseData { response in
                print("Response got: \(response)")
            }
    }
    
    static func hasLocalFile(for item: BaseItemDto, fileName: String) -> Bool {
        let fileURL = localFileURL(for: item, fileName: fileName)
        return FileManager.default.fileExists(atPath: fileURL.path)
    }
    
    static func localFileURL(for item: BaseItemDto, fileName: String) -> URL {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsURL.appendingPathComponent("\(item.id ?? "none")/\(fileName)")
    }
}
