//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

enum DownloadEntry: Hashable, Identifiable {
    case active(DownloadTask)
    case completed(DownloadItem)

    var id: String {
        switch self {
        case let .active(task):
            task.id
        case let .completed(item):
            item.id
        }
    }

    var item: BaseItemDto {
        switch self {
        case let .active(task):
            task.item
        case let .completed(item):
            item.item
        }
    }

    var active: DownloadTask? {
        if case let .active(task) = self { return task }
        return nil
    }

    var completed: DownloadItem? {
        if case let .completed(item) = self { return item }
        return nil
    }
}

extension DownloadEntry: Displayable {

    var displayTitle: String {
        item.displayTitle
    }
}

extension DownloadEntry: LibraryIdentifiable {

    var unwrappedIDHashOrZero: Int {
        id.hashValue
    }
}

extension DownloadEntry: SystemImageable {

    var systemImage: String {
        item.systemImage
    }
}

extension DownloadEntry {

    var seasonEpisodeLabel: String? {
        item.seasonEpisodeLabel
    }

    var premiereDateYear: String? {
        item.premiereDateYear
    }

    var runTimeLabel: String? {
        item.runTimeLabel
    }

    var officialRating: String? {
        item.officialRating
    }

    var type: BaseItemKind? {
        item.type
    }

    func compare(to other: DownloadEntry, by sort: ItemSortBy) -> Bool {
        switch (self, other) {
        case let (.completed(l), .completed(r)):
            l.compare(to: r, by: sort)
        default:
            displayTitle < other.displayTitle
        }
    }
}
