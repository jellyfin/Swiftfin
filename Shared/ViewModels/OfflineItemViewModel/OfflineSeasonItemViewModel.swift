//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import Foundation
import JellyfinAPI

// Since we don't view care to view seasons directly, this doesn't subclass from `ItemViewModel`.
// If we ever care for viewing seasons directly, subclass from that and have the library view model
// as a property.
final class OfflineSeasonItemViewModel: PagingLibraryViewModel<BaseItemDto> {
    @Injected(Container.downloadManager)
    private var downloadManager;

    let season: BaseItemDto

    init(season: BaseItemDto) {
        self.season = season
        super.init(parent: season)
    }

    override func get(page: Int) async throws -> [BaseItemDto] {
        downloadManager.downloads
            .filter { download in download.item.seasonID == season.id }
            .map(\.item)
            .sorted { ($0.indexNumber ?? -1) < ($1.indexNumber ?? -1) }
    }
}

extension OfflineSeasonItemViewModel: Hashable {

    static func == (lhs: OfflineSeasonItemViewModel, rhs: OfflineSeasonItemViewModel) -> Bool {
        lhs.parent as! BaseItemDto == rhs.parent as! BaseItemDto
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine((parent as! BaseItemDto).hashValue)
    }
}
