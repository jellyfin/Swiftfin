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

final class PlaylistItemViewModel: ItemViewModel {

    // MARK: - Published Playlist Items

    @Published
    private(set) var playlistItems: [BaseItemDto] = []

    // MARK: - Task

    private var playlistItemTask: AnyCancellable?

    // MARK: - Override Response

    override func respond(to action: ItemViewModel.Action) -> ItemViewModel.State {

        switch action {
        case .backgroundRefresh, .refresh:
            let parentState = super.respond(to: action)

            playlistItemTask?.cancel()

            Task { [weak self] in
                guard let self else { return }

                await MainActor.run {
                    self.playlistItems.removeAll()
                }

                do {
                    let playlistItems = try await getPlaylistItems()

                    await MainActor.run {
                        self.playlistItems.append(contentsOf: playlistItems)
                    }

                    if let episodeItem = playlistItems.first {
                        await MainActor.run {
                            self.playButtonItem = episodeItem
                        }
                    }
                }
            }
            .store(in: &cancellables)
        default: ()
        }

        return super.respond(to: action)
    }

    // MARK: - Get Playlist Items

    private func getPlaylistItems() async throws -> [BaseItemDto] {
        var parameters = Paths.GetItemsByUserIDParameters()
        parameters.fields = .MinimumFields
        parameters.includeItemTypes = BaseItemKind.supportedCases
            .appending(.episode)
        parameters.parentID = item.id

        let request = Paths.getItemsByUserID(
            userID: userSession.user.id,
            parameters: parameters
        )
        let response = try await userSession.client.send(request)

        return response.value.items ?? []
    }
}
