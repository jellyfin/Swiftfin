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
import OrderedCollections

// TODO: Some rework is required for 10.10
class PlaylistViewModel: ViewModel, Stateful, Eventful {

    // MARK: - Events

    enum Event: Equatable {
        case added
        case removed
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

        // TODO: 10.10 remove this action
        case createPlaylist(CreatePlaylistDto)

        // TODO: 10.10 enable these actions
        // TODO: 10.10 build responses for these actions
        /*
         case createPlaylist(
            name: String,
            ids: [String]? = nil,
            mediaType: PlaylistViewModel.PlaylistType = .unknown,
            users: [String]? = nil,
            isPublic: Bool = false
         )
         case updatePlaylist(
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

    // MARK: - Background State

    enum BackgroundState: Hashable {
        case updatingPlaylist
    }

    // MARK: - State

    enum State: Hashable {
        case initial
        case content
        case error(JellyfinAPIError)
    }

    @Published
    final var state: State = .initial

    // MARK: - Published Selected Playlist Variables

    @Published
    var selectedPlaylist: BaseItemDto?
    @Published
    var selectedPlaylistItems: [BaseItemDto] = []

    // MARK: - Published All Available Playlist Variable

    @Published
    var playlists: [BaseItemDto] = []

    // MARK: - Background State(s)

    @Published
    var backgroundStates: OrderedSet<BackgroundState> = []

    // MARK: - Event Variables

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
                    await MainActor.run {
                        _ = self.backgroundStates.append(.updatingPlaylist)
                    }

                    // Add item(s) to the selected playlist
                    try await self.addItems(itemIDs)

                    await MainActor.run {
                        _ = self.backgroundStates.append(.updatingPlaylist)
                        self.eventSubject.send(.added)
                    }
                } catch {
                    guard !Task.isCancelled else { return }
                    await MainActor.run {
                        _ = self.backgroundStates.remove(.updatingPlaylist)
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
                    await MainActor.run {
                        _ = self.backgroundStates.append(.updatingPlaylist)
                    }

                    // Remove item(s) from the selected playlist
                    try await self.removeItems(itemIDs)

                    await MainActor.run {
                        _ = self.backgroundStates.remove(.updatingPlaylist)
                        self.eventSubject.send(.removed)
                    }
                } catch {
                    guard !Task.isCancelled else { return }
                    await MainActor.run {
                        _ = self.backgroundStates.remove(.updatingPlaylist)
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
                    await MainActor.run {
                        _ = self.backgroundStates.append(.updatingPlaylist)
                    }

                    // Move an item to a new index in the selected playlist
                    try await self.moveItem(itemID: itemID, index: index)

                    await MainActor.run {
                        _ = self.backgroundStates.remove(.updatingPlaylist)
                        self.eventSubject.send(.updated)
                    }
                } catch {
                    guard !Task.isCancelled else { return }
                    await MainActor.run {
                        _ = self.backgroundStates.remove(.updatingPlaylist)
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
                    await MainActor.run {
                        self.state = .initial
                    }

                    // Get all playlists available to the user
                    self.playlists = try await self.getPlaylists()

                    await MainActor.run {
                        self.state = .content
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

        case let .setPlaylist(newPlaylist):
            playlistsTask?.cancel()

            playlistsTask = Task { [weak self] in
                guard let self = self else { return }
                do {
                    await MainActor.run {
                        _ = self.backgroundStates.append(.updatingPlaylist)
                    }

                    // Set the selected playlist to the new playlist
                    try await setPlaylist(newPlaylist)

                    // Get the playlist items for the new selected playlist
                    self.selectedPlaylistItems = try await getPlaylistItems()

                    await MainActor.run {
                        _ = self.backgroundStates.remove(.updatingPlaylist)
                    }
                } catch {
                    guard !Task.isCancelled else { return }
                    await MainActor.run {
                        _ = self.backgroundStates.remove(.updatingPlaylist)
                        self.eventSubject.send(.error(JellyfinAPIError(error.localizedDescription)))
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
                    await MainActor.run {
                        _ = self.backgroundStates.append(.updatingPlaylist)
                    }

                    // Create a new playlist from parameters
                    let newPlaylistID = try await self.createPlaylist(parameters: parameters)

                    // Get the full playlist BaseItemDto from the server
                    let newPlaylist = try await self.getPlaylist(id: newPlaylistID)

                    // Set the selected playlist to the new playlist
                    try await setPlaylist(newPlaylist)

                    // Get the playlist items for the new selected playlist
                    self.selectedPlaylistItems = try await getPlaylistItems()

                    await MainActor.run {
                        _ = self.backgroundStates.remove(.updatingPlaylist)
                        self.eventSubject.send(.created)
                    }
                } catch {
                    guard !Task.isCancelled else { return }
                    await MainActor.run {
                        _ = self.backgroundStates.remove(.updatingPlaylist)
                        self.eventSubject.send(.error(JellyfinAPIError(error.localizedDescription)))
                    }
                }
            }
            .asAnyCancellable()

            return state
        }
    }

    // MARK: - Add Item(s) to the Selected Playlist

    private func addItems(_ itemIDs: [String]) async throws {
        guard let playlistID = selectedPlaylist?.id else {
            throw JellyfinAPIError("A playlist must be selected before adding items to it")
        }

        let request = Paths.addToPlaylist(playlistID: playlistID, ids: itemIDs)
        _ = try await userSession.client.send(request)

        let newItems = try await getPlaylistItems()

        await MainActor.run {
            self.selectedPlaylistItems = newItems
        }
    }

    // MARK: - Remove Item(s) from the Selected Playlist

    private func removeItems(_ itemIDs: [String]) async throws {
        guard let playlistID = selectedPlaylist?.id else {
            throw JellyfinAPIError("A playlist must be selected before removing items from it")
        }

        let request = Paths.removeFromPlaylist(playlistID: playlistID, entryIDs: itemIDs)
        _ = try await userSession.client.send(request)

        await MainActor.run {
            self.selectedPlaylistItems.removeAll { item in
                item.id.map(itemIDs.contains) ?? false
            }
        }
    }

    // MARK: - Move an Item to a New Index in the Selected Playlist

    private func moveItem(itemID: String, index: Int) async throws {
        guard let playlistID = selectedPlaylist?.id else {
            throw JellyfinAPIError("A playlist must be selected before moving items in it")
        }

        let request = Paths.moveItem(playlistID: playlistID, itemID: itemID, newIndex: index)
        _ = try await userSession.client.send(request)

        await MainActor.run {
            if let currentIndex = selectedPlaylistItems.firstIndex(where: { $0.id == itemID }) {
                let item = selectedPlaylistItems.remove(at: currentIndex)
                let newIndex = min(max(index, 0), selectedPlaylistItems.count)
                selectedPlaylistItems.insert(item, at: newIndex)
            }
        }
    }

    // MARK: - Create a Playlist from Parameters

    private func createPlaylist(parameters: CreatePlaylistDto) async throws -> String {
        let request = Paths.createPlaylist(parameters)
        let response = try await userSession.client.send(request)

        guard let newPlaylist = response.value.id else {
            throw JellyfinAPIError("Failed to create a playlist")
        }

        return newPlaylist
    }

    // TODO: 10.10 use this create func instead
    /* private func createPlaylist(
          name: String,
          ids: [String]? = nil,
          mediaType: PlaylistViewModel.PlaylistType = .unknown,
          users: [String]? = nil,
          isPublic: Bool = false
      ) async throws -> String {

          let parameters = Paths.CreatePlaylistParameters(
              name: name,
              ids: ids,
              userID: userSession.user.id,
              mediaType: mediaType.rawValue,
              users: users,
              isPublic: isPublic
          )
          let request = Paths.createPlaylist(parameters)
          let response = try await userSession.client.send(request)

          guard let newPlaylist = response.value.id else {
              throw JellyfinAPIError("Failed to create playlist")
          }

          return newPlaylist
     } */

    // MARK: - Validate & Set the Playlist from a BaseItemDto

    private func setPlaylist(_ newPlaylist: BaseItemDto?) async throws {
        // Check if the New Playlist is a BaseItemDto or Nil
        if let newPlaylist {
            // Ensure that the BaseItemDto is a valid Playlist
            if newPlaylist.type == .playlist {
                await MainActor.run {
                    self.selectedPlaylist = newPlaylist
                }
            } else {
                throw JellyfinAPIError("The provided item is not a playlist")
            }
        } else {
            await MainActor.run {
                self.selectedPlaylist = nil
            }
        }
    }

    // MARK: - Get All Available Playlists for this User

    private func getPlaylists() async throws -> [BaseItemDto] {

        var parameters = Paths.GetItemsByUserIDParameters()
        parameters.fields = .MinimumFields
        parameters.isRecursive = true
        parameters.includeItemTypes = [.playlist]

        let request = Paths.getItemsByUserID(
            userID: userSession.user.id,
            parameters: parameters
        )
        let response = try await userSession.client.send(request)

        return response.value.items ?? []
    }

    // MARK: - Get Playlist BaseItemDto from its Id

    private func getPlaylist(id: String) async throws -> BaseItemDto {

        var parameters = Paths.GetItemsByUserIDParameters()
        parameters.fields = .MinimumFields
        parameters.includeItemTypes = [.playlist]
        parameters.ids = [id]

        let request = Paths.getItemsByUserID(
            userID: userSession.user.id,
            parameters: parameters
        )
        let response = try await userSession.client.send(request)

        guard let foundPlaylist = response.value.items?.first! else {
            throw JellyfinAPIError("This playlist does not exist")
        }

        return foundPlaylist
    }

    // MARK: - Get All Playlist Items for the Selected Playlist

    private func getPlaylistItems() async throws -> [BaseItemDto] {
        guard let playlistID = selectedPlaylist?.id else {
            return []
        }

        var parameters = Paths.GetItemsByUserIDParameters()
        parameters.fields = .MinimumFields
        parameters.parentID = playlistID

        // Hide unsupported item types
        parameters.includeItemTypes = [.movie, .episode, .series, .boxSet, .video]

        let request = Paths.getItemsByUserID(
            userID: userSession.user.id,
            parameters: parameters
        )
        let response = try await userSession.client.send(request)

        return response.value.items ?? []
    }
}
