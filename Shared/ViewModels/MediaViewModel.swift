//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import JellyfinAPI

final class MediaViewModel: ViewModel {

    @Published
    private var libraries: [BaseItemDto] = []
    
    var libraryItems: [MediaItemViewModel] {
        libraries.map({ .init(item: $0) })
            .prepending(
                .init(item: .init(name: "LiveTV", collectionType: "liveTV")),
                if: Defaults[.Experimental.liveTVAlphaEnabled]
            )
            .prepending(
                .init(item: .init(name: L10n.favorites, collectionType: "favorites")),
                if: Defaults[.Customization.Library.showFavorites]
            )
    }

    private static let supportedCollectionTypes: [String] = ["boxsets", "folders", "movies", "tvshows", "unknown"]

    override init() {
        super.init()

        requestLibraries()
    }

    func requestLibraries() {
        UserViewsAPI.getUserViews(userId: SessionManager.main.currentLogin.user.id)
            .trackActivity(loading)
            .sink(receiveCompletion: { completion in
                self.handleAPIRequestError(completion: completion)
            }, receiveValue: { response in
                guard let items = response.items else { return }
                let filteredLibraries = items.filter { Self.supportedCollectionTypes.contains($0.collectionType ?? "unknown") }

                self.libraries = filteredLibraries
            })
            .store(in: &cancellables)
    }
}
