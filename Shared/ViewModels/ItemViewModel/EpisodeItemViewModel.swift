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

final class EpisodeItemViewModel: ItemViewModel {

    @Published
    var seriesItem: BaseItemDto?

    override init(item: BaseItemDto) {
        super.init(item: item)

        getSeriesItem()
    }

    override func updateItem() {
        ItemsAPI.getItems(
            userId: SessionManager.main.currentLogin.user.id,
            limit: 1,
            fields: [
                .primaryImageAspectRatio,
                .seriesPrimaryImage,
                .seasonUserData,
                .overview,
                .genres,
                .people,
                .chapters,
            ],
            enableUserData: true,
            ids: [item.id ?? ""]
        )
        .sink { completion in
            self.handleAPIRequestError(completion: completion)
        } receiveValue: { response in
            if let item = response.items?.first {
                self.item = item
                self.playButtonItem = item
            }
        }
        .store(in: &cancellables)
    }

    private func getSeriesItem() {
        guard let seriesID = item.seriesId else { return }

        ItemsAPI.getItems(
            userId: SessionManager.main.currentLogin.user.id,
            limit: 1,
            fields: ItemFields.allCases,
            enableUserData: true,
            ids: [seriesID]
        )
        .trackActivity(loading)
        .sink(receiveCompletion: { [weak self] completion in
            self?.handleAPIRequestError(completion: completion)
        }, receiveValue: { [weak self] response in
            guard let firstItem = response.items?.first else { return }
            self?.seriesItem = firstItem
        })
        .store(in: &cancellables)
    }
}
