//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import JellyfinAPI
import OrderedCollections

final class MediaViewModel: ViewModel, Stateful {

    // TODO: remove once collection types become an enum
    static let supportedCollectionTypes: [String] = ["boxsets", "folders", "movies", "tvshows", "livetv"]

    // MARK: Action

    enum Action: Equatable {
        case error(JellyfinAPIError)
        case refresh
    }

    // MARK: State

    enum State: Hashable {
        case content
        case error(JellyfinAPIError)
        case initial
        case refreshing
    }

    @Published
    var mediaItems: OrderedSet<MediaType> = []

    @Published
    final var state: State = .initial
    @Published
    final var lastAction: Action? = nil

    func respond(to action: Action) -> State {
        switch action {
        case let .error(error):
            return .error(error)
        case .refresh:
            cancellables.removeAll()

            Task {
                do {
                    try await refresh()

                    await MainActor.run {
                        self.state = .content
                    }
                } catch {
                    await MainActor.run {
                        self.state = .error(.init(error.localizedDescription))
                    }
                }
            }
            .store(in: &cancellables)

            return .refreshing
        }
    }

    private func refresh() async throws {

        await MainActor.run {
            mediaItems.removeAll()
        }

        let media: [MediaType] = try await getUserViews()
            .compactMap { userView in
                if userView.collectionType == "livetv" {
                    return .liveTV(userView)
                }

                return .collectionFolder(userView)
            }
            .prepending(.favorites, if: Defaults[.Customization.Library.showFavorites])

        await MainActor.run {
            mediaItems.elements = media
        }
    }

    private func getUserViews() async throws -> [BaseItemDto] {

        let userViewsPath = Paths.getUserViews(userID: userSession.user.id)
        async let userViews = userSession.client.send(userViewsPath)

        async let excludedLibraryIDs = getExcludedLibraries()

        // folders has `type = UserView`, but we manually
        // force it to `folders` for better view handling
        let supportedUserViews = try await (userViews.value.items ?? [])
            .intersection(Self.supportedCollectionTypes, using: \.collectionType)
            .subtracting(excludedLibraryIDs, using: \.id)
            .map { item in

                if item.type == .userView, item.collectionType == "folders" {
                    return item.mutating(\.type, with: .folder)
                }

                return item
            }

        return supportedUserViews
    }

    private func getExcludedLibraries() async throws -> [String] {
        let currentUserPath = Paths.getCurrentUser
        let response = try await userSession.client.send(currentUserPath)

        return response.value.configuration?.myMediaExcludes ?? []
    }

    func randomItemImageSources(for mediaType: MediaType) async throws -> [ImageSource] {

        // live tv doesn't have random
        if case MediaType.liveTV = mediaType {
            return []
        }

        // downloads doesn't have random
        if mediaType == .downloads {
            return []
        }

        var parentID: String?

        if case let MediaType.collectionFolder(item) = mediaType {
            parentID = item.id
        }

        var filters: [ItemTrait]?

        if mediaType == .favorites {
            filters = [.isFavorite]
        }

        var parameters = Paths.GetItemsByUserIDParameters()
        parameters.limit = 3
        parameters.isRecursive = true
        parameters.parentID = parentID
        parameters.includeItemTypes = [.movie, .series, .boxSet]
        parameters.filters = filters
        parameters.sortBy = [ItemSortBy.random.rawValue]

        let request = Paths.getItemsByUserID(userID: userSession.user.id, parameters: parameters)
        let response = try await userSession.client.send(request)

        return (response.value.items ?? [])
            .map { $0.imageSource(.backdrop, maxWidth: 200) }
    }
}
