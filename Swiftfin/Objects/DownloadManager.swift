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
    let tmpDirectory: URL
    private(set) var offlineItems = Set<OfflineItem>()
    
    private init() {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let downloadsDirectory = documentsDirectory.appendingPathComponent("Downloads")
        
        try! FileManager.default.createDirectory(at: downloadsDirectory,
                                                 withIntermediateDirectories: true,
                                                 attributes: nil)
        
        self.downloadsDirectory = downloadsDirectory
        self.tmpDirectory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
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
    
    func addDownload(playbackInfo: PlaybackInfoResponse, item: BaseItemDto, fileName: String) throws {
        guard let itemID = item.id else { throw JellyfinAPIError("Cannot get item ID") }
        guard let itemFileURL = item.getDownloadURL() else { throw JellyfinAPIError("Cannot get item download URL") }
        
        let itemTmpDirectory = tmpDirectory.appendingPathComponent(itemID, isDirectory: true)

        let destination: DownloadRequest.Destination = { _, _ in
            let mediaFileURL = itemTmpDirectory.appendingPathComponent(fileName)
            
            return (mediaFileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        let afDownload = AF.download(itemFileURL, to: destination)
        let newDownloadTracker = DownloadTracker(afDownload,
                                                 playbackInfo: playbackInfo,
                                                 item: item,
                                                 itemDirectory: itemTmpDirectory)
        
        let newOfflineItem = OfflineItem(playbackInfo: playbackInfo,
                                         item: item,
                                         itemDirectory: itemTmpDirectory,
                                         primaryImageURL: item.getPrimaryImage(maxWidth: 300),
                                         backdropImageURL: item.getBackdropImage(maxWidth: 500),
                                         downloadTracker: newDownloadTracker)
        
        offlineItems.insert(newOfflineItem)
        
        Notifications[.didAddDownload].post()
    }
    
    func removeDownload(offlineItem: OfflineItem) {
        self.offlineItems.remove(offlineItem)
    }
    
    func hasLocalFile(for item: BaseItemDto, fileName: String) -> Bool {
        let fileURL = localFileURL(for: item, fileName: fileName)
        return FileManager.default.fileExists(atPath: fileURL.path)
    }
    
    func localFileURL(for item: BaseItemDto, fileName: String) -> URL {
        return downloadsDirectory.appendingPathComponent("\(item.id ?? "none")/\(fileName)")
    }
    
    func hasDownloadDirectory(for item: BaseItemDto) -> Bool {
        var isDir: ObjCBool = true
        let itemDirectory = downloadsDirectory.appendingPathComponent("\(item.id ?? "none")", isDirectory: true)
        return FileManager.default.fileExists(atPath: itemDirectory.path, isDirectory: &isDir)
    }
    
    func offlineItem(for item: BaseItemDto) -> OfflineItem? {
        return offlineItems.first(where: { $0.item.id == item.id })
    }
    
    // MARK: GetOfflineItems
    func getOfflineItems() -> [OfflineItem] {
        do {
            let downloadDirectoryContents = try FileManager.default.contentsOfDirectory(atPath: downloadsDirectory.path)
            
            var offlineItems: [OfflineItem] = []
            
            for itemDirectory in downloadDirectoryContents {
                let itemDirectory = downloadsDirectory.appendingPathComponent(itemDirectory, isDirectory: true)

                do {
                    let newOfflineItem = try parseOfflineItem(at: itemDirectory)
                    
                    offlineItems.append(newOfflineItem)
                } catch {
                    //
                }
            }
            
            return offlineItems
        } catch {
            return []
        }
    }
    
    func getTmpSize() -> String {
        return (try? tmpDirectory.sizeOnDisk()) ?? "none"
    }
    
    func clearTmpDirectory() {
        DispatchQueue.global(qos: .background).async {
            let tmpContents = try! FileManager.default.contentsOfDirectory(atPath: self.tmpDirectory.path)

            for content in tmpContents {
                let fullContent = self.tmpDirectory.appendingPathComponent(content, isDirectory: true)

                try! FileManager.default.removeItem(atPath: fullContent.path)

                print("Removed: \(content)")
            }
        }
    }
    
    func deleteItem(_ offlineItem: OfflineItem) {
        try! FileManager.default.removeItem(at: offlineItem.itemDirectory)
        
        Notifications[.didDeleteOfflineItem].post(object: nil)
    }
    
    private func parseOfflineItem(at itemDirectory: URL) throws -> OfflineItem {
        let itemContents = try FileManager.default.contentsOfDirectory(atPath: itemDirectory.path)
        
        guard itemContents.count >= 3 else { throw JellyfinAPIError("Wrong number of base items") }
        
        guard let itemJSONFile = itemContents.first(where: { $0 == "item.json" }),
              let playbackJSONFile = itemContents.first(where: { $0 == "playbackInfo.json" }) else { throw JellyfinAPIError("Cannot find item or playback info json files") }
        
        let itemJSONPath = itemDirectory.appendingPathComponent(itemJSONFile)
        let playbackJSONPath = itemDirectory.appendingPathComponent(playbackJSONFile)
        
        guard let itemJSONData = FileManager.default.contents(atPath: itemJSONPath.path),
              let playbackJSONData = FileManager.default.contents(atPath: playbackJSONPath.path) else { throw JellyfinAPIError("Cannot properly open item or playback info json files") }
        
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
        
        let primaryImageURL: URL?
        
        if let primaryFile = itemContents.first(where: { $0 == "primary.png" }),
           let _ = FileManager.default.contents(atPath: itemDirectory.appendingPathComponent(primaryFile).path) {
            
            primaryImageURL = itemDirectory.appendingPathComponent(primaryFile)
        } else {
            primaryImageURL = nil
        }
        
        let newOfflineItem = OfflineItem(playbackInfo: playbackInfo,
                                         item: item,
                                         itemDirectory: itemDirectory,
                                         primaryImageURL: primaryImageURL,
                                         backdropImageURL: backdropImageURL,
                                         downloadTracker: nil)
        
        return newOfflineItem
    }
}
