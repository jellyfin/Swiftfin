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
    
    private(set) var downloadingItems = Set<OfflineItem>()
    private let downloadsDirectory: URL
    private let tmpDirectory: URL
    private let documentsDirectory: URL
    
    var tmpSize: Int {
        return tmpDirectory.sizeOnDisk
    }
    
    var downloadsSize: Int {
        return downloadsDirectory.sizeOnDisk
    }
    
    private init() {
        self.documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.downloadsDirectory = documentsDirectory.appendingPathComponent("Downloads")
        self.tmpDirectory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        
        AF.sessionConfiguration.requestCachePolicy = .reloadIgnoringLocalCacheData
        
        try! FileManager.default.createDirectory(at: downloadsDirectory,
                                                 withIntermediateDirectories: true,
                                                 attributes: nil)
    }
    
    var availableStoragLabel: String? {
        let byteCountFormatter = ByteCountFormatter()
        byteCountFormatter.countStyle = .file
        return byteCountFormatter.string(fromByteCount: availableStorage)
    }
    
    var availableStorage: Int64 {
        let availableStorage: Int64
        
        let fileURL = URL(fileURLWithPath: NSHomeDirectory() as String)
        
        do {
            let values = try fileURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
            
            if let capacity = values.volumeAvailableCapacityForImportantUsage {
                availableStorage = capacity
            } else {
                availableStorage = -1
            }
        } catch {
            availableStorage = -1
        }
        
        return availableStorage
    }
    
    func hasSpace(for fileSize: Int64) -> Bool {
        return fileSize < availableStorage
    }
    
    // MARK: addDownload
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
        
        downloadingItems.insert(newOfflineItem)
        
        Notifications[.didAddDownload].post()
    }
    
    func removeDownload(for offlineItem: OfflineItem) {
        self.downloadingItems.remove(offlineItem)
    }
    
    func hasDownloadDirectory(for item: BaseItemDto, fileName: String) -> Bool {
        let fileURL = downloadDirectory(for: item, fileName: fileName)
        return FileManager.default.fileExists(atPath: fileURL.path)
    }
    
    func downloadDirectory(for item: BaseItemDto, fileName: String) -> URL {
        return downloadsDirectory.appendingPathComponent("\(item.id ?? "none")/\(fileName)")
    }
    
    func hasDownloadDirectory(for item: BaseItemDto) -> Bool {
        var isDir: ObjCBool = true
        let itemDirectory = downloadsDirectory.appendingPathComponent("\(item.id ?? "none")", isDirectory: true)
        return FileManager.default.fileExists(atPath: itemDirectory.path, isDirectory: &isDir)
    }
    
    func downloadingItem(for item: BaseItemDto) -> OfflineItem? {
        return downloadingItems.first(where: { $0.item.id == item.id })
    }
    
    func offlineItem(for item: BaseItemDto) -> OfflineItem? {
        guard DownloadManager.main.hasDownloadDirectory(for: item) else { return nil }
        
        let itemDirectory = downloadsDirectory.appendingPathComponent("\(item.id ?? "none")", isDirectory: true)
        
        do {
            return try parseOfflineItem(at: itemDirectory)
        } catch {
            return nil
        }
    }
    
    // MARK: GetOfflineItems
    func getOfflineItems() -> [OfflineItem] {
        do {
            let downloadDirectoryContents = try FileManager.default.contentsOfDirectory(atPath: downloadsDirectory.path)
            
            var offlineItems: [OfflineItem] = []
            
            for itemDirectory in downloadDirectoryContents {
                let itemDirectoryURL = downloadsDirectory.appendingPathComponent(itemDirectory, isDirectory: true)

                do {
                    let newOfflineItem = try parseOfflineItem(at: itemDirectoryURL)
                    
                    offlineItems.append(newOfflineItem)
                } catch {
                    LogManager.shared.log.error("Couldn't parse offline item with path: \(itemDirectory)")
                }
            }
            
            return offlineItems
        } catch {
            return []
        }
    }
    
    // MARK: Delete and clear
    func deleteItem(_ offlineItem: OfflineItem) {
        try! FileManager.default.removeItem(at: offlineItem.itemDirectory)
        
        Notifications[.didDeleteOfflineItem].post()
    }
    
    func clearTmp() {
        DispatchQueue.global(qos: .background).async {
            let tmpContents = try! FileManager.default.contentsOfDirectory(atPath: self.tmpDirectory.path)

            for item in tmpContents {
                let itemURL = self.tmpDirectory.appendingPathComponent(item, isDirectory: true)
                
                do {
                    try FileManager.default.removeItem(atPath: itemURL.path)
                } catch {
                    LogManager.shared.log.error("Couldn't delete path from tmp directory: \(item)")
                    return
                }
            }
            
            LogManager.shared.log.debug("Cleared tmp directory")
            
            Notifications[.didDeleteOfflineItem].post()
        }
    }
    
    func clearDownloads() {
        DispatchQueue.global(qos: .background).async {
            let downloadContents = try! FileManager.default.contentsOfDirectory(atPath: self.downloadsDirectory.path)
            
            for download in downloadContents {
                let fullContent = self.downloadsDirectory.appendingPathComponent(download, isDirectory: true)
                
                do {
                    try FileManager.default.removeItem(atPath: fullContent.path)
                } catch {
                    LogManager.shared.log.error("Couldn't delete path from tmp directory: \(download)")
                    return
                }
            }
            
            LogManager.shared.log.debug("Cleared downloads directory")
            
            Notifications[.didDeleteOfflineItem].post()
        }
    }
    
    // MARK: ParseOfflineItem
    
    private func parseOfflineItem(at itemDirectory: URL) throws -> OfflineItem {
        let itemContents = try FileManager.default.contentsOfDirectory(atPath: itemDirectory.path)
        
        guard itemContents.count >= 3 else { throw JellyfinAPIError("Incorrect number of base items") }
        
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
