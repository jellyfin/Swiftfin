//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

struct DownloadItem: Codable, Hashable, Identifiable, Displayable, LibraryIdentifiable, SystemImageable, Storable {

    let id: String
    let item: BaseItemDto
    let mediaRelativePath: String
    let images: [DownloadImage]
    let completedAt: Date

    var downloadFolder: URL {
        item.downloadFolder ?? URL.swiftfinDownloads.appendingPathComponent(id, isDirectory: true)
    }

    var imagesFolder: URL {
        downloadFolder.appendingPathComponent("Images", isDirectory: true)
    }

    var mediaURL: URL {
        downloadFolder.appendingPathComponent(mediaRelativePath)
    }

    var displayTitle: String {
        item.displayTitle
    }

    var unwrappedIDHashOrZero: Int {
        id.hashValue
    }

    var systemImage: String {
        item.systemImage
    }

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

    func localFileURL(for serverURL: URL) -> URL? {
        let path = serverURL.path
        if let match = images.first(where: { $0.pathKey == path }) {
            return imagesFolder.appendingPathComponent(match.relativePath)
        }
        if let last = serverURL.pathComponents.last,
           let kind = ImageType(rawValue: last.lowercased()),
           let match = images.first(where: { $0.pathKey == "legacy:\(kind.rawValue)" })
        {
            return imagesFolder.appendingPathComponent(match.relativePath)
        }
        return nil
    }

    func compare(to other: DownloadItem, by sort: ItemSortBy) -> Bool {
        switch sort {
        case .sortName, .name:
            (item.sortName ?? displayTitle) < (other.item.sortName ?? other.displayTitle)
        case .premiereDate:
            (item.premiereDate ?? .distantPast) < (other.item.premiereDate ?? .distantPast)
        case .productionYear:
            (item.productionYear ?? 0) < (other.item.productionYear ?? 0)
        case .dateCreated:
            (item.dateCreated ?? .distantPast) < (other.item.dateCreated ?? .distantPast)
        case .runtime:
            (item.runTimeTicks ?? 0) < (other.item.runTimeTicks ?? 0)
        case .communityRating:
            (item.communityRating ?? 0) < (other.item.communityRating ?? 0)
        case .criticRating:
            (item.criticRating ?? 0) < (other.item.criticRating ?? 0)
        default:
            (item.sortName ?? displayTitle) < (other.item.sortName ?? other.displayTitle)
        }
    }
}
