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

final class SeasonItemViewModel: DetailItemViewModel {
    @Published var episodes = [BaseItemDto]()

    override init(item: BaseItemDto) {
        super.init(item: item)
        self.item = item

        requestEpisodes()
    }

    func requestEpisodes() {
        LogManager.shared.log.debug("Getting episodes in season \(self.item.id!) (\(self.item.name!)) of show \(self.item.seriesId!) (\(self.item.seriesName!))")
        TvShowsAPI.getEpisodes(seriesId: item.seriesId ?? "", userId: SessionManager.current.user.user_id!,
                               fields: [.primaryImageAspectRatio, .seriesPrimaryImage, .seasonUserData, .overview, .genres, .people],
                               seasonId: item.id ?? "")
            .trackActivity(loading)
            .sink(receiveCompletion: { [weak self] completion in
                self?.handleAPIRequestCompletion(completion: completion)
            }, receiveValue: { [weak self] response in
                self?.episodes = response.items ?? []
                LogManager.shared.log.debug("Retrieved \(String(self?.episodes.count ?? 0)) episodes")
            })
            .store(in: &cancellables)
    }
}
