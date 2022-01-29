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
import Nuke
import UIKit

enum DownloadState {
    case downloading
    case paused
    case cancelled
    case idle
    case done
    case error
}

struct OfflineItem: Hashable {
    let playbackInfo: PlaybackInfoResponse
    let item: BaseItemDto
    let itemDirectory: URL
    let backdropImageURL: URL?
    var storage: String {
        return try! itemDirectory.sizeOnDisk() ?? "-- MB"
    }
}

class DownloadTracker: ObservableObject {
    
    @Published var progress: Double = 0
    @Published var state: DownloadState = .idle
    
    let downloadRequest: DownloadRequest
    let playbackInfo: PlaybackInfoResponse
    let item: BaseItemDto
    let itemDirectory: URL
    let markDate: Date
    
    init(_ downloadRequest: DownloadRequest,
         playbackInfo: PlaybackInfoResponse,
         item: BaseItemDto,
         itemDirectory: URL) {
        self.downloadRequest = downloadRequest
        self.playbackInfo = playbackInfo
        self.item = item
        self.itemDirectory = itemDirectory
        self.markDate = Date.now
    }
    
    func start() {
        guard !downloadRequest.isCancelled else { return }
        
        state = .downloading
        
        saveMetadata()
        saveBackdrop()
        
        downloadRequest
            .downloadProgress { progress in
                self.progress = progress.fractionCompleted
            }
            .responseData { response in
                
                if let error = response.error {
                    self.state = .error
                    print(error.errorDescription ?? "error with download")
                } else {
                    DownloadManager.main.removeDownload(self)
                    
                    self.state = .done
                }
            }
    }
    
    func cancel() {
        downloadRequest.cancel()
        state = .cancelled
    }
    
    func pause() {
        downloadRequest.suspend()
        state = .paused
    }
    
    func resume() {
        downloadRequest.resume()
        state = .downloading
    }
    
    private func saveMetadata() {
        
        // Create item directory
        try! FileManager.default.createDirectory(at: itemDirectory,
                                                 withIntermediateDirectories: true,
                                                 attributes: nil)
        
        let jsonEncoder = JSONEncoder()
        
        let itemJsonData = try! jsonEncoder.encode(item)
        let itemJson = String(data: itemJsonData, encoding: .utf8)
        let itemFileURL = itemDirectory.appendingPathComponent("item.json")
        
        try! itemJson?.write(to: itemFileURL, atomically: true, encoding: .utf8)
        
        let playbackJsonData = try! jsonEncoder.encode(playbackInfo)
        let playbackJson = String(data: playbackJsonData, encoding: .utf8)
        let playbackFileURL = itemDirectory.appendingPathComponent("playbackInfo.json")
        
        try! playbackJson?.write(to: playbackFileURL, atomically: true, encoding: .utf8)
    }
    
    private func saveBackdrop() {
        let backdropImageURL = item.getBackdropImage(maxWidth: 150)

        let destination: DownloadRequest.Destination = { _, _ in
            let mediaFileURL = self.itemDirectory.appendingPathComponent("backdrop.png")
            
            return (mediaFileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        let afDownload = AF.download(backdropImageURL, to: destination)
        afDownload
            .responseData { response in
                if let _ = response.error {
                    LogManager.shared.log.error("Error downloading item backdrop")
                } else {
                    //
                }
            }
    }
}

extension DownloadTracker: Hashable, Equatable {
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(markDate)
        hasher.combine(downloadRequest.id)
    }
    
    static func == (lhs: DownloadTracker, rhs: DownloadTracker) -> Bool {
        return lhs.downloadRequest.id == rhs.downloadRequest.id
    }
}
