//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import JellyfinAPI

final class MediaViewModel: ViewModel {

    @Published
    private var libraries: [BaseItemDto] = []

    var libraryItems: [MediaItemViewModel] {
        libraries.map { .init(item: $0) }
            .prepending(
                .init(item: .init(collectionType: "liveTV", name: "LiveTV")),
                if: Defaults[.Experimental.liveTVAlphaEnabled]
            )
            .prepending(
                .init(item: .init(collectionType: "favorites", name: L10n.favorites)),
                if: Defaults[.Customization.Library.showFavorites]
            )
            .prepending(
                .init(item: .init(collectionType: "downloads", name: "Downloads")),
                if: Defaults[.Experimental.downloads]
            )
    }

    private static let supportedCollectionTypes: [String] = ["boxsets", "folders", "movies", "tvshows", "unknown"]

    override init() {
        super.init()

        requestLibraries()
    }

    func requestLibraries() {
        Task {
            let request = Paths.getUserViews(userID: userSession.user.id)
            let response = try await userSession.client.send(request)

            guard let items = response.value.items else { return }
            let supportedLibraries = items.filter { Self.supportedCollectionTypes.contains($0.collectionType ?? "unknown") }

            await MainActor.run {
                libraries = supportedLibraries
            }
        }
    }
}
