//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import Factory
import Foundation
import JellyfinAPI

final class OfflineNextUpLibraryViewModel: PagingLibraryViewModel<BaseItemDto> {
    @Injected(Container.downloadManager)
    private var downloadManager;

    init() {
        super.init(parent: TitledLibraryParent(displayTitle: L10n.nextUp, id: "nextUp"))
    }

    override func get(page: Int) async throws -> [BaseItemDto] {
        let resumeItems = downloadManager.downloads.filter { item in item.item.userData?.playedPercentage ?? 0 > 5 }
        let series = downloadManager.shellDownloads
            .filter { download in download.item.type == .series }
            .map { download in download.item }

        var nextUpResults: [BaseItemDto] = []
        for show in series {
            if resumeItems.contains(where: { item in item.item.seriesID == show.id }) {
                continue
            }

            let sortedEpisodes = downloadManager.downloads
                .filter { download in download.item.seriesID == show.id }
                .sorted { ($0.item.indexNumber ?? -1) < ($1.item.indexNumber ?? -1) }
                .sorted { ($0.seasonItem?.indexNumber ?? -1) < ($1.seasonItem?.indexNumber ?? -1) }
            guard let lastPlayedItemIndex = sortedEpisodes.firstIndex(where: { $0.item.userData?.isPlayed ?? false }) else { continue }

            for i in lastPlayedItemIndex + 1 ... sortedEpisodes.count {
                if sortedEpisodes[i].item.userData?.isPlayed ?? false {
                    continue
                }
                nextUpResults.append(sortedEpisodes[i].item)
                break
            }
        }
        return nextUpResults
    }
}
