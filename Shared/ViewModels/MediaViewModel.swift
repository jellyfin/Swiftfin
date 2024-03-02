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

final class MediaViewModel: ViewModel {

    // TODO: remove once collection types become an enum
    static let supportedCollectionTypes: [String] = ["boxsets", "folders", "movies", "tvshows", "livetv"]

    @Published
    var libraries: OrderedSet<MediaItemViewModel> = []

    func refresh() async {
        do {
            let newLibraries = try await getUserLibraries()

            await MainActor.run {
                libraries.elements = newLibraries.map(MediaItemViewModel.init)
//                    .prepending(
//                        .init(item: .init(collectionType: "favorites", name: L10n.favorites)),
//                        if: Defaults[.Customization.Library.showFavorites]
//                    )
//                    .prepending(
//                        .init(item: .init(collectionType: "downloads", name: L10n.downloads)),
//                        if: Defaults[.Experimental.downloads]
//                    )
            }
        } catch {
            // TODO: set error once MediaView has error + retry state
            await MainActor.run {
                libraries = []
            }
        }
    }

    private func getUserLibraries() async throws -> [BaseItemDto] {
        let request = Paths.getUserViews(userID: userSession.user.id)
        let response = try await userSession.client.send(request)

        guard let items = response.value.items else { return [] }

        // folders has `type = UserView`, but we manually
        // force it to `folders` for better view handling
        let supportedLibraries = items
            .filtered(using: \.collectionType, by: Self.supportedCollectionTypes)
            .map { item in

                if item.type == .userView, item.collectionType == "folders" {
                    return item.mutating(\.type, with: .folder)
                }

                return item
            }

        return supportedLibraries
    }
}
