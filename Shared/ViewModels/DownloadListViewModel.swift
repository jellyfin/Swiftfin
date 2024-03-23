//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Factory
import JellyfinAPI
import SwiftUI

class DownloadListItem {
    let id: String
    var children: [DownloadListItem]
    let displayName: String
    let baseItem: BaseItemDto?

    init(id: String, displayName: String, children: [DownloadListItem] = [], baseItem: BaseItemDto? = nil) {
        self.id = id
        self.children = children
        self.displayName = displayName
        self.baseItem = baseItem
    }
}

class DownloadListViewModel: ViewModel {

    @Injected(Container.downloadManager)
    private var downloadManager

    @Published
    var items: [DownloadTask] = []
//    var items: [DownloadListItem] = []

    override init() {
        super.init()

        items = downloadManager.downloadedItems()

//        for downloadTask in downloadManager.downloadedItems() {
//            switch downloadTask.item.type {
//            case .episode:
//                if let seriesId = downloadTask.item.seriesID, let seriesName = downloadTask.item.seriesName {
//                    let seriesItem = items.first { $0.id == seriesId } ?? {
//                        let newItem = DownloadListItem(id: seriesId, displayName: seriesName)
//                        items.append(newItem)
//                        return newItem
//                    }()
//                    if let seasonId = downloadTask.item.seasonID, let seasonName = downloadTask.item.seasonName {
//                        let seasonItem = items.first { $0.id == seasonId } ?? {
//                            let newItem = DownloadListItem(id: seasonId, displayName: seasonName)
//                            seriesItem.children.append(newItem)
//                            return newItem
//                        }()
//                        if let mediaId = downloadTask.item.id, let mediaName = downloadTask.item.name {
//                            seasonItem.children.append(DownloadListItem(id: mediaId, displayName: mediaName, baseItem: downloadTask.item))
//                        }
//                    } else {
//                        if let mediaId = downloadTask.item.id, let mediaName = downloadTask.item.name {
//                            seriesItem.children.append(DownloadListItem(id: mediaId, displayName: mediaName, baseItem: downloadTask.item))
//                        }
//                    }
//                } else {
//                    if let mediaId = downloadTask.item.id, let mediaName = downloadTask.item.name {
//                        items.append(DownloadListItem(id: mediaId, displayName: mediaName, baseItem: downloadTask.item))
//                    }
//                }
//            case .movie:
//                if let movieId = downloadTask.item.id, let movieName = downloadTask.item.name {
//                    items.append(DownloadListItem(id: movieId, displayName: movieName, baseItem: downloadTask.item))
//                }
//            default: continue
//            }
//        }
    }
}
