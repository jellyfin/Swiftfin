//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import JellyfinAPI
import OrderedCollections

final class MediaViewModel: ViewModel, Stateful {

    // TODO: remove once collection types become an enum
    static let supportedCollectionTypes: [String] = ["boxsets", "folders", "movies", "tvshows", "livetv"]

    enum MediaType: Displayable, Hashable {
        case downloads
        case favorites
        case liveTV
        case userView(BaseItemDto)

        var displayTitle: String {
            switch self {
            case .downloads:
                return L10n.downloads
            case .favorites:
                return L10n.favorites
            case .liveTV:
                return L10n.liveTV
            case let .userView(item):
                return item.displayTitle
            }
        }
    }

    // MARK: Action

    enum Action {
        case error(JellyfinAPIError)
        case refresh
    }

    // MARK: State

    enum State: Equatable {
        case content
        case error(JellyfinAPIError)
        case initial
        case refreshing
    }

    @Published
    var mediaItems: OrderedSet<MediaType> = []

    @Published
    var state: State = .initial

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

        let media = try await getUserViews()
            .map(MediaType.userView)
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

        var parentID: String?

        if case let MediaType.userView(item) = mediaType {
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
            .map { $0.imageSource(.backdrop, maxWidth: 500) }
    }
}
