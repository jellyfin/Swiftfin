//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
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

    override func updateItem() {}

    private func getSeriesItem() {
        guard let seriesID = item.seriesID else { return }
        Task {
            let parameters = Paths.GetItemsParameters(
                userID: userSession.user.id,
                limit: 1,
                fields: ItemFields.allCases,
                enableUserData: true,
                ids: [seriesID]
            )
            let request = Paths.getItems(parameters: parameters)
            let response = try await userSession.client.send(request)

            await MainActor.run {
                seriesItem = response.value.items?.first
            }
        }
    }
}
