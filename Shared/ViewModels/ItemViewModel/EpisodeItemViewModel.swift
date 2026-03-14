//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI

final class EpisodeItemViewModel: ItemViewModel {

    // MARK: - Published Episode Items

    @Published
    private(set) var seriesItem: BaseItemDto?

    // MARK: - Task

    private var seriesItemTask: AnyCancellable?

    // MARK: - Override Response

    override func respond(to action: ItemViewModel.Action) -> ItemViewModel.State {

        switch action {
        case .refresh, .backgroundRefresh:
            seriesItemTask?.cancel()

            seriesItemTask = Task {
                let seriesItem = try await self.getSeriesItem()

                await MainActor.run {
                    self.seriesItem = seriesItem
                }
            }
            .asAnyCancellable()
        default: ()
        }

        return super.respond(to: action)
    }

    // MARK: - Get Series Items

    private func getSeriesItem() async throws -> BaseItemDto {

        guard let seriesID = item.seriesID else { throw ErrorMessage("Expected series ID missing") }

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

        guard let seriesItem = response.value.items?.first else { throw ErrorMessage("Expected series item missing") }

        return seriesItem
    }
}
