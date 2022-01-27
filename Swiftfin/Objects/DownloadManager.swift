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

class DownloadTracker: ObservableObject {
    
    @Published var progress: Double = 0
    let downloadRequest: DownloadRequest
    let item: BaseItemDto
    let startDate: Date
    
    init(_ downloadRequest: DownloadRequest, item: BaseItemDto) {
        self.downloadRequest = downloadRequest
        self.item = item
        self.startDate = Date.now
    }
    
    func start() {
        guard !downloadRequest.isCancelled else { return }
        
        downloadRequest
            .downloadProgress { progress in
                self.progress = progress.fractionCompleted
            }
            .responseData { response in
                DownloadManager.main.removeDownload(self)
                let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let jsonEncoder = JSONEncoder()
                let jsonData = try! jsonEncoder.encode(self.item)
                let json = String(data: jsonData, encoding: .utf8)
                let itemFileURL = documentsURL.appendingPathComponent("\(self.item.id ?? "none")/item-data.json")
                
                try! json?.write(to: itemFileURL, atomically: true, encoding: .utf8)
            }
    }
    
    func cancel() {
        downloadRequest.cancel()
    }
    
    func pause() {
        downloadRequest.suspend()
    }
    
    func resume() {
        downloadRequest.resume()
    }
}

extension DownloadTracker: Hashable, Equatable {
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(startDate)
        hasher.combine(downloadRequest.id)
    }
    
    static func == (lhs: DownloadTracker, rhs: DownloadTracker) -> Bool {
        return lhs.downloadRequest.id == rhs.downloadRequest.id
    }
}

class DownloadManager {
    
    static let main = DownloadManager()
    
    private init() { }
    
    private(set) var trackers = Set<DownloadTracker>()
    
    var totalStorageUsed: Int {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        let values = try! documents.resourceValues(forKeys: [.volumeAvailableCapacityForOpportunisticUsageKey])
        if let capacity = values.volumeTotalCapacity {
            return capacity
        } else {
            return 0
        }
    }
    
    func addDownload(item: BaseItemDto, fileName: String) {
        guard let itemFileURL = item.getDownloadURL() else { return }

        let destination: DownloadRequest.Destination = { _, _ in
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsURL.appendingPathComponent("\(item.id ?? "none")/\(fileName)")
            
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        let newDownload = DownloadTracker(AF.download(itemFileURL, to: destination), item: item)
        
        trackers.insert(newDownload)
    }
    
    func removeDownload(_ download: DownloadTracker) {
        self.trackers.remove(download)
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
