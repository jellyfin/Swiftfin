//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Alamofire
import Combine
import Foundation
import JellyfinAPI
import Nuke
import UIKit

class DownloadManager {
    
    static let main = DownloadManager()
    
    let downloadsDirectory: URL
    private(set) var trackers = Set<DownloadTracker>()
    
    private init() {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let downloadsDirectory = documentsDirectory.appendingPathComponent("Downloads")
        
        try! FileManager.default.createDirectory(at: downloadsDirectory,
                                                 withIntermediateDirectories: true,
                                                 attributes: nil)
        
        self.downloadsDirectory = downloadsDirectory
    }
    
    var totalStorageUsed: Int {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        let values = try! documents.resourceValues(forKeys: [.volumeAvailableCapacityForOpportunisticUsageKey])
        if let capacity = values.volumeTotalCapacity {
            return capacity
        } else {
            return 0
        }
    }
    
    func addDownload(playbackInfo: PlaybackInfoResponse, item: BaseItemDto, fileName: String) {
        guard let itemFileURL = item.getDownloadURL() else { return }
        
        let itemDirectory = downloadsDirectory.appendingPathComponent("\(item.id ?? "error")", isDirectory: true)

        let destination: DownloadRequest.Destination = { _, _ in
            let mediaFileURL = itemDirectory.appendingPathComponent(fileName)
            
            return (mediaFileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        let afDownload = AF.download(itemFileURL, to: destination)
        let newDownload = DownloadTracker(afDownload,
                                          playbackInfo: playbackInfo,
                                          item: item,
                                          itemDirectory: itemDirectory)
        
        trackers.insert(newDownload)
    }
    
    func removeDownload(_ download: DownloadTracker) {
        self.trackers.remove(download)
    }
    
    func hasLocalFile(for item: BaseItemDto, fileName: String) -> Bool {
        let fileURL = localFileURL(for: item, fileName: fileName)
        return FileManager.default.fileExists(atPath: fileURL.path)
    }
    
    func localFileURL(for item: BaseItemDto, fileName: String) -> URL {
        return downloadsDirectory.appendingPathComponent("\(item.id ?? "none")/\(fileName)")
    }
    
    // MARK: GetOfflineItems
    func getOfflineItems() -> [OfflineItem] {
        do {
            let downloadDirectoryContents = try FileManager.default.contentsOfDirectory(atPath: downloadsDirectory.path)
            
            var offlineItems: [OfflineItem] = []
            
            for itemDirectory in downloadDirectoryContents {
                let itemDirectory = downloadsDirectory.appendingPathComponent(itemDirectory, isDirectory: true)
                let itemContents = try FileManager.default.contentsOfDirectory(atPath: itemDirectory.path)
                
                guard itemContents.count >= 3 else { continue }
                
                guard let itemJSONFile = itemContents.first(where: { $0 == "item.json" }),
                      let playbackJSONFile = itemContents.first(where: { $0 == "playbackInfo.json" }) else { continue }
                
                let itemJSONPath = itemDirectory.appendingPathComponent(itemJSONFile)
                let playbackJSONPath = itemDirectory.appendingPathComponent(playbackJSONFile)
                
                guard let itemJSONData = FileManager.default.contents(atPath: itemJSONPath.path),
                      let playbackJSONData = FileManager.default.contents(atPath: playbackJSONPath.path) else { continue }
                
                let decoder = JSONDecoder()
                
                let item = try decoder.decode(BaseItemDto.self, from: itemJSONData)
                let playbackInfo = try decoder.decode(PlaybackInfoResponse.self, from: playbackJSONData)
                
                let backdropImageURL: URL?
                
                if let backdropFile = itemContents.first(where: { $0 == "backdrop.png" }),
                   let _ = FileManager.default.contents(atPath: itemDirectory.appendingPathComponent(backdropFile).path) {
                    
                    backdropImageURL = itemDirectory.appendingPathComponent(backdropFile)
                } else {
                    backdropImageURL = nil
                }
                
                let newOfflineItem = OfflineItem(playbackInfo: playbackInfo,
                                                 item: item,
                                                 itemDirectory: itemDirectory,
                                                 backdropImageURL: backdropImageURL)
                
                offlineItems.append(newOfflineItem)
            }
            
            return offlineItems
        } catch {
            return []
        }
    }
    
    func deleteItem(_ offlineItem: OfflineItem) {
        try! FileManager.default.removeItem(at: offlineItem.itemDirectory)
        
        SwiftfinNotificationCenter.main.post(name: SwiftfinNotificationCenter.Keys.didDeleteOfflineItem, object: nil)
    }
}
