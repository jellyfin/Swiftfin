//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

class OfflineItem {
    
    let playbackInfo: PlaybackInfoResponse
    let item: BaseItemDto
    let itemDirectory: URL
    let primaryImageURL: URL?
    let backdropImageURL: URL?
    let downloadTracker: DownloadTracker?
    
    var storageLabel: String? {
        return itemDirectory.sizeOnDiskLabel
    }
    
    init(playbackInfo: PlaybackInfoResponse,
         item: BaseItemDto,
         itemDirectory: URL,
         primaryImageURL: URL?,
         backdropImageURL: URL?,
         downloadTracker: DownloadTracker?) {
        self.playbackInfo = playbackInfo
        self.item = item
        self.itemDirectory = itemDirectory
        self.primaryImageURL = primaryImageURL
        self.backdropImageURL = backdropImageURL
        self.downloadTracker = downloadTracker
    }
}

extension OfflineItem: Equatable, Hashable {
    
    static func ==(lhs: OfflineItem, rhs: OfflineItem) -> Bool {
        return lhs.item == rhs.item
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(item)
    }
}
