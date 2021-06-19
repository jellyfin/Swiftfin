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

final class SeasonItemViewModel: ViewModel {
    @Published
    var item: BaseItemDto

    @Published
    var episodes = [BaseItemDto]()

    init(item: BaseItemDto) {
        self.item = item
        super.init()

        requestEpisodes()
    }

    func requestEpisodes() {
        TvShowsAPI.getEpisodes(seriesId: item.seriesId ?? "", userId: SessionManager.current.user.user_id!,
                               fields: [.primaryImageAspectRatio, .seriesPrimaryImage, .seasonUserData, .overview, .genres, .people],
                               seasonId: item.id ?? "")
            .trackActivity(loading)
            .sink(receiveCompletion: { [weak self] completion in
                self?.handleAPIRequestCompletion(completion: completion)
            }, receiveValue: { [weak self] response in
                self?.episodes = response.items ?? []
            })
            .store(in: &cancellables)
    }
}
