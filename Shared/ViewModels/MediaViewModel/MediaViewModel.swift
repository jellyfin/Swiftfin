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

@MainActor
@Stateful
final class MediaViewModel: ViewModel {

    @CasePathable
    enum Action {
        case refresh

        var transition: Transition {
            .loop(.refreshing)
        }
    }

    enum State {
        case error
        case initial
        case refreshing
    }

    @Published
    private(set) var mediaItems: OrderedSet<MediaType> = []

    @Function(\Action.Cases.refresh)
    private func _refresh() async throws {

        mediaItems.removeAll()

        let media: [MediaType] = try await getUserViews()
            .compactMap { userView in
                if userView.collectionType == .livetv {
                    return .liveTV(userView)
                }

                return .collectionFolder(userView)
            }
            .prepending(.favorites, if: Defaults[.Customization.Library.showFavorites])

        mediaItems.elements = media
    }

    private func getUserViews() async throws -> [BaseItemDto] {

        let parameters = Paths.GetUserViewsParameters(userID: userSession.user.id)
        let userViewsPath = Paths.getUserViews(parameters: parameters)
        async let userViews = userSession.client.send(userViewsPath)

        async let excludedLibraryIDs = getExcludedLibraries()

        // folders has `type = UserView`, but we manually
        // force it to `folders` for better view handling
        let supportedUserViews = try await (userViews.value.items ?? [])
            .coalesced(property: \.collectionType, with: .folders)
            .intersection(CollectionType.supportedCases, using: \.collectionType)
            .subtracting(excludedLibraryIDs, using: \.id)
            .map { item in

                if item.type == .userView, item.collectionType == .folders {
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
