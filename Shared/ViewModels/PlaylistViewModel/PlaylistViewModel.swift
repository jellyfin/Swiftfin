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

// TODO: Some rework is required for 10.10
class PlaylistViewModel: ViewModel, Stateful, Eventful {

    // MARK: - Events

    enum Event: Equatable {
        case updated
        case created
        case error(JellyfinAPIError)
    }

    // MARK: - Action

    enum Action: Equatable {
        case addItems([String])
        case removeItems([String])
        case moveItem(itemID: String, index: Int)
        case getPlaylists
        case setPlaylist(BaseItemDto?)
        case createPlaylist(CreatePlaylistDto)

        // TODO: Enable & build logic out for 10.10
        /* case updatePlaylist(
             playlistID: String,
             name: String? = nil,
             ids: [String]? = nil,
             userCanEdit: [String: Bool]? = nil,
             isPublic: Bool? = nil
         )
         case getUsers
         case editUser(playlistID: String, userID: String, canEdit: Bool)
         case removeUser(playlistID: String, userID: String) */
    }

    // MARK: - State

    enum State: Hashable {
        case initial
        case updating
        case content
        case error(JellyfinAPIError)
    }

    @Published
    final var state: State = .initial

    // MARK: - Published Item

    @Published
    var selectedPlaylist: BaseItemDto?

    @Published
    var items: [BaseItemDto] = []

    @Published
    var playlists: [BaseItemDto] = []

    // MARK: Event Variables

    private var playlistsTask: AnyCancellable?
    private var eventSubject: PassthroughSubject<Event, Never> = .init()

    var events: AnyPublisher<Event, Never> {
        eventSubject
            .eraseToAnyPublisher()
        // Causes issues with the Deleted Event unless this is removed
        // .receive(on: RunLoop.main)
    }

    // MARK: - Initializer

    init(playlist: BaseItemDto? = nil) {
        if let playlist {
            if playlist.type == .playlist {
                self.selectedPlaylist = playlist
            } else {
                assertionFailure("The provided item must be a playlist")
            }
        } else {
            self.selectedPlaylist = nil
        }
    }

    // MARK: - Respond

    func respond(to action: Action) -> State {
        switch action {
        case let .addItems(itemIDs):
            playlistsTask?.cancel()

            playlistsTask = Task { [weak self] in
                guard let self = self else { return }
                do {
                    try await self.addItems(itemIDs)
                    await MainActor.run {
                        self.eventSubject.send(.updated)
                    }
                } catch {
                    guard !Task.isCancelled else { return }
                    await MainActor.run {
                        self.eventSubject.send(.error(JellyfinAPIError(error.localizedDescription)))
                    }
                }
            }
            .asAnyCancellable()

            return state

        case let .removeItems(itemIDs):
            playlistsTask?.cancel()

            playlistsTask = Task { [weak self] in
                guard let self = self else { return }
                do {
                    try await self.removeItems(itemIDs)
                    await MainActor.run {
                        self.eventSubject.send(.updated)
                    }
                } catch {
                    guard !Task.isCancelled else { return }
                    await MainActor.run {
                        self.eventSubject.send(.error(JellyfinAPIError(error.localizedDescription)))
                    }
                }
            }
            .asAnyCancellable()

            return state

        case let .moveItem(itemID, index):
            playlistsTask?.cancel()

            playlistsTask = Task { [weak self] in
                guard let self = self else { return }
                do {
                    try await self.moveItem(itemID: itemID, index: index)
                    await MainActor.run {
                        self.eventSubject.send(.updated)
                    }
                } catch {
                    guard !Task.isCancelled else { return }
                    await MainActor.run {
                        self.eventSubject.send(.error(JellyfinAPIError(error.localizedDescription)))
                    }
                }
            }
            .asAnyCancellable()

            return state

        case .getPlaylists:
            playlistsTask?.cancel()

            playlistsTask = Task { [weak self] in
                guard let self = self else { return }
                do {
                    try await self.getPlaylists()
                    await MainActor.run {
                        self.state = .content
                    }
                } catch {
                    guard !Task.isCancelled else { return }
                    await MainActor.run {
                        self.state = .error(JellyfinAPIError(error.localizedDescription))
                        self.eventSubject.send(.error(JellyfinAPIError(error.localizedDescription)))
                    }
                }
            }
            .asAnyCancellable()

            return state

        case let .setPlaylist(newPlaylist):
            playlistsTask?.cancel()

            playlistsTask = Task { [weak self] in
                guard let self = self else { return }
                do {
                    self.selectedPlaylist = newPlaylist
                    try await getPlaylistItems()
                    await MainActor.run {
                        self.state = .updating
                    }
                } catch {
                    guard !Task.isCancelled else { return }
                    await MainActor.run {
                        self.state = .error(JellyfinAPIError(error.localizedDescription))
                    }
                }
            }
            .asAnyCancellable()

            return state

        case let .createPlaylist(parameters):
            playlistsTask?.cancel()

            playlistsTask = Task { [weak self] in
                guard let self = self else { return }
                do {
                    try await self.createPlaylist(parameters: parameters)
                    await MainActor.run {
                        self.eventSubject.send(.created)
                    }
                } catch {
                    guard !Task.isCancelled else { return }
                    await MainActor.run {
                        self.eventSubject.send(.error(JellyfinAPIError(error.localizedDescription)))
                    }
                }
            }
            .asAnyCancellable()

            return state
        }
    }

    // MARK: - Add Item(s) to Playlist

    private func addItems(_ itemIDs: [String]) async throws {
        guard let playlistID = selectedPlaylist?.id else {
            throw JellyfinAPIError(L10n.unknownError)
        }

        let request = Paths.addToPlaylist(playlistID: playlistID, ids: itemIDs)
        _ = try await userSession.client.send(request)
    }

    // MARK: - Remove Item(s) from Playlist

    private func removeItems(_ itemIDs: [String]) async throws {
        guard let playlistID = selectedPlaylist?.id else {
            throw JellyfinAPIError(L10n.unknownError)
        }

        let request = Paths.removeFromPlaylist(playlistID: playlistID, entryIDs: itemIDs)
        _ = try await userSession.client.send(request)
    }

    // MARK: - Move Item's Index in Playlist

    private func moveItem(itemID: String, index: Int) async throws {
        guard let playlistID = selectedPlaylist?.id else {
            throw JellyfinAPIError(L10n.unknownError)
        }

        let request = Paths.moveItem(playlistID: playlistID, itemID: itemID, newIndex: index)
        _ = try await userSession.client.send(request)
    }

    // MARK: - Create Playlist

    private func createPlaylist(parameters: CreatePlaylistDto) async throws {
        let request = Paths.createPlaylist(parameters)
        let response = try await userSession.client.send(request)

        try await setPlaylist(response.value.id!)
    }

    // This SHOULD be used but doesn't appear active in 10.8
    /* private func createPlaylist(
         name: String,
         ids: [String]? = nil,
         mediaType: PlaylistViewModel.PlaylistType = .unknown,
         users: [String]? = nil,
         isPublic: Bool = false
     ) async throws {

         let parameters = Paths.CreatePlaylistParameters(
             name: name,
             ids: ids,
             userID: userSession.user.id,
             mediaType: mediaType.rawValue,
             users: users,
             isPublic: isPublic
         )*/

    // MARK: - Get All Available Playlists

    private func getPlaylists() async throws {

        // TODO: Use ListItemViewModel instead? Can we page a Picker?

        var parameters = Paths.GetItemsByUserIDParameters()
        parameters.fields = .MinimumFields
        parameters.isRecursive = true
        parameters.includeItemTypes = [.playlist]

        let request = Paths.getItemsByUserID(
            userID: userSession.user.id,
            parameters: parameters
        )
        let response = try await userSession.client.send(request)

        await MainActor.run {
            self.playlists = response.value.items ?? []
        }
    }

    // MARK: - Get All Available Playlists

    private func setPlaylist(_ id: String) async throws {

        // TODO: Use ListItemViewModel instead? Or is this fine since it's one Playlist?

        var parameters = Paths.GetItemsByUserIDParameters()
        parameters.fields = .MinimumFields
        parameters.mediaTypes = ["playlist"]
        parameters.ids = [id]

        let request = Paths.getItemsByUserID(
            userID: userSession.user.id,
            parameters: parameters
        )
        let response = try await userSession.client.send(request)

        guard let foundPlaylist = response.value.items?.first! else {
            throw JellyfinAPIError("No playlist found")
        }

        await MainActor.run {
            self.selectedPlaylist = foundPlaylist
        }
    }

    // MARK: - Get All Playlist Items

    private func getPlaylistItems() async throws {
        guard let playlistID = selectedPlaylist?.id else {
            throw JellyfinAPIError(L10n.unknownError)
        }

        // TODO: 100% this should use ListItemViewModel instead

        var parameters = Paths.GetItemsByUserIDParameters()
        parameters.fields = .MinimumFields
        parameters.parentID = playlistID

        // Hide unsupported item types
        parameters.includeItemTypes = [.movie, .episode, .series, .boxSet]

        let request = Paths.getItemsByUserID(
            userID: userSession.user.id,
            parameters: parameters
        )
        let response = try await userSession.client.send(request)

        await MainActor.run {
            self.items = response.value.items ?? []
        }
    }
}
