//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI
import Stinsen

final class EpisodeItemViewModel: ItemViewModel {

    @Published
    private(set) var seriesItem: BaseItemDto?

    private var seriesItemTask: AnyCancellable?

    override init(item: BaseItemDto) {
        super.init(item: item)

        $lastAction
            .sink { [weak self] action in
                guard let self else { return }

                if action == .refresh {
                    seriesItemTask?.cancel()

                    seriesItemTask = Task {
                        let seriesItem = try await self.getSeriesItem()

                        await MainActor.run {
                            self.seriesItem = seriesItem
                        }
                    }
                    .asAnyCancellable()
                }
            }
            .store(in: &cancellables)
    }

    private func getSeriesItem() async throws -> BaseItemDto {

        guard let seriesID = item.seriesID else { throw JellyfinAPIError("Expected series ID missing") }

        var parameters = Paths.GetItemsByUserIDParameters()
        parameters.enableUserData = true
        parameters.fields = .MinimumFields
        parameters.ids = [seriesID]
        parameters.limit = 1

        let request = Paths.getItemsByUserID(
            userID: userSession.user.id,
            parameters: parameters
        )
        let response = try await userSession.client.send(request)

        guard let seriesItem = response.value.items?.first else { throw JellyfinAPIError("Expected series item missing") }

        return seriesItem
    }
}
