//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

struct DownloadItemDto: Hashable, Identifiable, Displayable, LibraryIdentifiable, SystemImageable {

    weak var manager: DownloadManager?

    let record: DownloadRecord
    let item: BaseItemDto

    init?(record: DownloadRecord, manager: DownloadManager? = nil) {
        guard let item = record.item else { return nil }
        self.record = record
        self.item = item
        self.manager = manager
    }

    var id: String? {
        record.id
    }

    var displayTitle: String {
        item.displayTitle
    }

    var unwrappedIDHashOrZero: Int {
        record.id.hashValue
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

    func imageURL(for kind: ImageType) -> URL? {
        guard let url = record.imageURL(for: kind),
              FileManager.default.fileExists(atPath: url.path)
        else { return nil }
        return url
    }

    func imageAspectRatio(for kind: ImageType) -> CGFloat? {
        record.images.first(where: { $0.kind == kind })?.aspectRatio
    }

    static func == (lhs: DownloadItemDto, rhs: DownloadItemDto) -> Bool {
        lhs.record.id == rhs.record.id && lhs.record.updatedAt == rhs.record.updatedAt
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(record.id)
    }

    func compare(to other: DownloadItemDto, by sort: ItemSortBy) -> Bool {
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
