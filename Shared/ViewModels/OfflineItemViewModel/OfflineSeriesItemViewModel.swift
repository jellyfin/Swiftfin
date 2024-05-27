//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import Factory
import Foundation
import JellyfinAPI
import OrderedCollections

// TODO: care for one long episodes list?
//       - after SeasonItemViewModel is bidirectional
//       - would have to see if server returns right amount of episodes/season
final class OfflineSeriesItemViewModel: OfflineItemViewModel {
    @Injected(Container.downloadManager)
    private var downloadManager;

    @Published
    var seasons: OrderedSet<OfflineSeasonItemViewModel> = []

    override func onRefresh() async throws {

        await MainActor.run {
            self.seasons.removeAll()
        }

        async let nextUp = getNextUp()
        async let resume = getResumeItem()
        async let firstAvailable = getFirstAvailableItem()
        async let seasons = getSeasons()

        let newSeasons = await seasons
            .sorted { ($0.indexNumber ?? -1) < ($1.indexNumber ?? -1) } // sort just in case
            .map(OfflineSeasonItemViewModel.init)

        await MainActor.run {
            self.seasons.append(contentsOf: newSeasons)
        }

        if let episodeItem = await [nextUp, resume].compacted().first {
            await MainActor.run {
                self.playButtonItem = episodeItem
            }
        } else if let firstAvailable = await firstAvailable {
            await MainActor.run {
                self.playButtonItem = firstAvailable
            }
        }
    }

    private func getNextUp() -> BaseItemDto? {
        if getResumeItem() != nil {
            return nil
        }

        let sortedEpisodes = downloadManager.downloads
            .filter { download in download.item.seriesID == item.id }
            .sorted { ($0.item.indexNumber ?? -1) < ($1.item.indexNumber ?? -1) }
            .sorted { ($0.seasonItem?.indexNumber ?? -1) < ($1.seasonItem?.indexNumber ?? -1) }
        guard let lastPlayedItemIndex = sortedEpisodes.firstIndex(where: { $0.item.userData?.isPlayed ?? false }) else { return nil }

        for i in lastPlayedItemIndex + 1 ... sortedEpisodes.count {
            if sortedEpisodes[i].item.userData?.isPlayed ?? false {
                continue
            }
            return sortedEpisodes[i].item
        }

        return nil
    }

    private func getResumeItem() -> BaseItemDto? {
        downloadManager.downloads
            .first { download in download.item.seriesID == item.id && download.item.userData?.playedPercentage ?? 0 > 5 }?.item
    }

    private func getFirstAvailableItem() -> BaseItemDto? {
        downloadManager.downloads.first { download in download.item.seriesID == item.id }?.item
    }

    private func getSeasons() -> [BaseItemDto] {
        downloadManager.shellDownloads
            .filter { download in download.item.seriesID == item.id }
            .map { download in download.item }
    }
}
