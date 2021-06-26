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

final class SeriesItemViewModel: ViewModel {
    @Published
    var item: BaseItemDto

    @Published
    var seasons = [BaseItemDto]()

    init(item: BaseItemDto) {
        self.item = item
        super.init()

        requestSeasons()
    }

    func requestSeasons() {
        TvShowsAPI.getSeasons(seriesId: item.id ?? "", userId: SessionManager.current.user.user_id!, fields: [.primaryImageAspectRatio, .seriesPrimaryImage, .seasonUserData, .overview, .genres, .people], enableUserData: true)
            .trackActivity(loading)
            .sink(receiveCompletion: { [weak self] completion in
                self?.handleAPIRequestCompletion(completion: completion)
            }, receiveValue: { [weak self] response in
                self?.seasons = response.items ?? []
            })
            .store(in: &cancellables)
    }
}
