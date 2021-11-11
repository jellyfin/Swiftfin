//
/*
 * SwiftFin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import Combine
import Foundation
import JellyfinAPI
import Stinsen

final class SeasonItemViewModel: ItemViewModel {
    @RouterObject var itemRouter: ItemCoordinator.Router?
    @Published private(set) var episodes: [BaseItemDto] = []

    override init(item: BaseItemDto) {
        super.init(item: item)
        self.item = item

        requestEpisodes()
    }

    override func playButtonText() -> String {
        guard let playButtonItem = playButtonItem else { return L10n.play }
        guard let episodeLocator = playButtonItem.getEpisodeLocator() else { return L10n.play }
        return episodeLocator
    }

    private func requestEpisodes() {
        LogManager.shared.log
            .debug("Getting episodes in season \(item.id!) (\(item.name!)) of show \(item.seriesId!) (\(item.seriesName!))")
        TvShowsAPI.getEpisodes(seriesId: item.seriesId ?? "", userId: SessionManager.main.currentLogin.user.id,
                               fields: [.primaryImageAspectRatio, .seriesPrimaryImage, .seasonUserData, .overview, .genres, .people],
                               seasonId: item.id ?? "")
            .trackActivity(loading)
            .sink(receiveCompletion: { [weak self] completion in
                self?.handleAPIRequestError(completion: completion)
            }, receiveValue: { [weak self] response in
                self?.episodes = response.items ?? []
                LogManager.shared.log.debug("Retrieved \(String(self?.episodes.count ?? 0)) episodes")

                self?.setNextUpInSeason()
            })
            .store(in: &cancellables)
    }

    // Sets the play button item to the "Next up" in the season based upon
    //     the watched status of episodes in the season.
    // Default to the first episode of the season if all have been watched.
    private func setNextUpInSeason() {
        guard !episodes.isEmpty else { return }

        var firstUnwatchedSearch: BaseItemDto?

        for episode in episodes {
            guard let played = episode.userData?.played else { continue }
            if !played {
                firstUnwatchedSearch = episode
                break
            }
        }

        if let firstUnwatched = firstUnwatchedSearch {
            playButtonItem = firstUnwatched
        } else {
            guard let firstEpisode = episodes.first else { return }
            playButtonItem = firstEpisode
        }
    }

    func routeToSeriesItem() {
        guard let id = item.seriesId else { return }
        UserLibraryAPI.getItem(userId: SessionManager.main.currentLogin.user.id, itemId: id)
            .trackActivity(loading)
            .sink(receiveCompletion: { [weak self] completion in
                self?.handleAPIRequestError(completion: completion)
            }, receiveValue: { [weak self] item in
                self?.itemRouter?.route(to: \.item, item)
            })
            .store(in: &cancellables)
    }
}
