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

@MainActor
@Stateful
final class ItemPlaylistViewModel: ViewModel {

    @CasePathable
    enum Action {
        /// The playlists the item should belong to on update.
        case update(playlistIDs: Set<String>, index: Int?)
        case create(name: String)
        case refresh

        var transition: Transition {
            switch self {
            case .refresh:
                .to(.initial, then: .content)
            case .create, .update:
                .background(.updating)
            }
        }
    }

    enum BackgroundState {
        case updating
    }

    enum Event {
        case updated
    }

    enum State {
        case initial
        case content
        case error
    }

    /// All playlists
    @Published
    private(set) var playlists: [BaseItemDto] = []

    /// Playlists that this item is contained in.
    @Published
    private(set) var containingPlaylists: Set<String> = []

    let item: BaseItemDto

    init(item: BaseItemDto) {
        self.item = item
        super.init()
    }

    @Function(\Action.Cases.refresh)
    private func _refresh() async throws {
        let userSession = try requireUserSession()

        var parameters = Paths.GetItemsParameters()
        parameters.fields = .MinimumFields
        parameters.includeItemTypes = [.playlist]
        parameters.isRecursive = true
        parameters.sortBy = [.sortName]
        parameters.sortOrder = [.ascending]
        parameters.userID = userSession.user.id

        let request = Paths.getItems(parameters: parameters)
        let response = try await userSession.client.send(request)

        playlists = response.value.items ?? []

        containingPlaylists = await withTaskGroup(of: String?.self) { group in
            for playlistID in playlists.compactMap(\.id) {
                group.addTask {
                    await self.playlistItemIDs(for: playlistID).isNotEmpty ? playlistID : nil
                }
            }

            var result: Set<String> = []

            for await playlistID in group {
                if let playlistID {
                    result.insert(playlistID)
                }
            }

            return result
        }
    }

    @Function(\Action.Cases.update)
    private func _update(_ playlistIDs: Set<String>, _ index: Int? = nil) async throws {
        let newPlaylists = playlistIDs.subtracting(containingPlaylists)
        let removedPlaylists = containingPlaylists.subtracting(playlistIDs)

        guard newPlaylists.isNotEmpty || removedPlaylists.isNotEmpty else { return }

        try await withThrowingTaskGroup(of: Void.self) { group in
            for playlistID in newPlaylists {
                group.addTask {
                    try await self.addItem(to: playlistID, at: index)
                }
            }

            for playlistID in removedPlaylists {
                group.addTask {
                    try await self.removeItem(from: playlistID)
                }
            }

            try await group.waitForAll()
        }

        events.send(.updated)
    }

    @Function(\Action.Cases.create)
    private func _create(_ name: String) async throws {
        guard let itemID = item.id else { return }

        let existingPlaylist = playlists.first {
            $0.displayTitle.localizedCaseInsensitiveCompare(name) == .orderedSame
        }

        // Add to the playlist if it already exists
        if let playlistID = existingPlaylist?.id {
            try await addItem(to: playlistID)
            events.send(.updated)
            return
        }

        let parameters = try CreatePlaylistDto(
            ids: [itemID],
            name: name,
            userID: authenticatedUser.id
        )

        let request = Paths.createPlaylist(parameters)
        _ = try await send(request)

        events.send(.updated)
    }

    /// Return all playlists that this user can see that this item is contained in.
    private func playlistItemIDs(for playlistID: String) async -> [String] {
        guard let itemID = item.id else { return [] }

        let request = Paths.getPlaylistItems(
            playlistID: playlistID,
            parameters: .init(userID: try? authenticatedUser.id)
        )

        guard let response = try? await send(request) else { return [] }

        return (response.value.items ?? [])
            .filter { $0.id == itemID }
            .compactMap(\.playlistItemID)
    }

    private func addItem(to playlistID: String, at index: Int? = nil) async throws {
        guard let itemID = item.id else { return }

        let parameters = Paths.AddItemToPlaylistParameters(
            ids: [itemID],
            position: index
        )

        let request = Paths.addItemToPlaylist(
            playlistID: playlistID,
            parameters: parameters
        )

        _ = try await send(request)

        Notifications[.itemShouldRefreshMetadata].post(playlistID)
    }

    private func removeItem(from playlistID: String) async throws {
        let entryIDs = await playlistItemIDs(for: playlistID)

        guard entryIDs.isNotEmpty else { return }

        let request = Paths.removeItemFromPlaylist(
            playlistID: playlistID,
            entryIDs: entryIDs
        )
        _ = try await send(request)

        Notifications[.itemShouldRefreshMetadata].post(playlistID)
    }
}
