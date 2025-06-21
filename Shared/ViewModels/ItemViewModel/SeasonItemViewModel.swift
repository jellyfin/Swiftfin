//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import Foundation
import JellyfinAPI

final class SeasonItemViewModel: ItemViewModel, Identifiable {

    // MARK: - Published Episode Items

    @Published
    private(set) var episodes: [BaseItemDto] = []

    var season: BaseItemDto {
        item
    }

    var id: String? {
        season.id
    }

    // MARK: - Task

    private var episodesTask: AnyCancellable?

    // MARK: - Override Response

    override func respond(to action: ItemViewModel.Action) -> ItemViewModel.State {

        switch action {
        case .refresh, .backgroundRefresh:
            episodesTask?.cancel()

            episodesTask = Task {
                let episodes = try await self.getEpisodes()

                await MainActor.run {
                    self.episodes = episodes
                }
            }
            .asAnyCancellable()
        default: break
        }

        return super.respond(to: action)
    }

    // MARK: - Get Episodes

    private func getEpisodes() async throws -> [BaseItemDto] {

        var parameters = Paths.GetEpisodesParameters()
        parameters.enableUserData = true
        parameters.fields = .MinimumFields
        parameters.isMissing = Defaults[.Customization.shouldShowMissingEpisodes] ? nil : false
        parameters.seasonID = season.id
        parameters.userID = userSession.user.id

        let request = Paths.getEpisodes(
            seriesID: season.seriesID!,
            parameters: parameters
        )
        let response = try await userSession.client.send(request)

        return response.value.items ?? []
    }
}
