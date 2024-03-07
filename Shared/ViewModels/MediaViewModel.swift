//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import Foundation
import JellyfinAPI
import OrderedCollections

// TODO: refactor so that we aren't depending on the `collectionType` for special local types
//       - have an enum `MediaViewType` on the item view models?
// TODO: transition to `Stateful`
// TODO: excluded userviews
final class MediaViewModel: ViewModel, Stateful {

    // TODO: remove once collection types become an enum
    static let supportedCollectionTypes: [String] = ["boxsets", "folders", "movies", "tvshows", "livetv"]

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
    var mediaItems: OrderedSet<MediaItemViewModel> = []

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

        let userViews = try await getUserViews()
            .map { MediaItemViewModel(type: .userView($0)) }

        let allMediaItems = userViews
            .prepending(.init(type: .favorites), if: Defaults[.Customization.Library.showFavorites])

        await MainActor.run {
            mediaItems.append(contentsOf: allMediaItems)
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

        return response.value.configuration?.latestItemsExcludes ?? []
    }
}
