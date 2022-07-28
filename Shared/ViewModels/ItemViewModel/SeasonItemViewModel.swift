//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI
import Stinsen

final class SeasonItemViewModel: ItemViewModel, EpisodesRowManager {

    @RouterObject
    private var itemRouter: ItemCoordinator.Router?
    @Published
    var seasonsEpisodes: [BaseItemDto: [BaseItemDto]] = [:]
    @Published
    var selectedSeason: BaseItemDto?

    override init(item: BaseItemDto) {
        super.init(item: item)

        selectedSeason = item
//        getSeasons()
        requestEpisodes()
    }

    override func playButtonText() -> String {

        if item.unaired {
            return L10n.unaired
        }

        guard let playButtonItem = playButtonItem, let episodeLocator = playButtonItem.episodeLocator else { return L10n.play }
        return episodeLocator
    }

    private func requestEpisodes() {
        LogManager.log
            .debug("Getting episodes in season \(item.id!) (\(item.name!)) of show \(item.seriesId!) (\(item.seriesName!))")
        TvShowsAPI.getEpisodes(
            seriesId: item.seriesId ?? "",
            userId: SessionManager.main.currentLogin.user.id,
            fields: [.primaryImageAspectRatio, .seriesPrimaryImage, .seasonUserData, .overview, .genres, .people],
            seasonId: item.id ?? ""
        )
        .trackActivity(loading)
        .sink(receiveCompletion: { [weak self] completion in
            self?.handleAPIRequestError(completion: completion)
        }, receiveValue: { [weak self] response in
            guard let self = self else { return }
            self.seasonsEpisodes[self.item] = response.items ?? []

            self.setNextUpInSeason()
        })
        .store(in: &cancellables)
    }

    private func setNextUpInSeason() {

        TvShowsAPI.getNextUp(
            userId: SessionManager.main.currentLogin.user.id,
            fields: [.primaryImageAspectRatio, .seriesPrimaryImage, .seasonUserData, .overview, .genres, .people],
            seriesId: item.seriesId ?? "",
            enableUserData: true
        )
        .trackActivity(loading)
        .sink(receiveCompletion: { [weak self] completion in
            self?.handleAPIRequestError(completion: completion)
        }, receiveValue: { [weak self] response in
            guard let self = self else { return }

            // Find the nextup item that belongs to current season.
            if let nextUpItem = (response.items ?? []).first(where: { episode in
                !episode.unaired && !episode.missing && episode.seasonId ?? "" == self.item.id!
            }) {
                self.playButtonItem = nextUpItem
                LogManager.log.debug("Nextup in season \(self.item.id!) (\(self.item.name!)): \(nextUpItem.id!)")
            }

            //				if self.playButtonItem == nil && !self.episodes.isEmpty {
            //					// Fallback to the old mechanism:
            //					// Sets the play button item to the "Next up" in the season based upon
            //					// the watched status of episodes in the season.
            //					// Default to the first episode of the season if all have been watched.
            //					var firstUnwatchedSearch: BaseItemDto?
//
            //					for episode in self.episodes {
            //						guard let played = episode.userData?.played else { continue }
            //						if !played {
            //							firstUnwatchedSearch = episode
            //							break
            //						}
            //					}
//
            //					if let firstUnwatched = firstUnwatchedSearch {
            //						self.playButtonItem = firstUnwatched
            //					} else {
            //						guard let firstEpisode = self.episodes.first else { return }
            //						self.playButtonItem = firstEpisode
            //					}
            //				}
        })
        .store(in: &cancellables)
    }
}
