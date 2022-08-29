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
    var libraries: [BaseItemDto] = []
    @Published
    var libraryImages: [String: [ImageSource]] = [:]

    private var supportedLibraries: [String] {
        ["movies", "tvshows", "unknown"]
            .appending("livetv", if: Defaults[.Experimental.liveTVAlphaEnabled])
    }

    override init() {
        super.init()

        requestLibraries()
        getRandomItemImageSource(with: [.isFavorite], id: nil, key: "favorites")
    }

    func requestLibraries() {
        UserViewsAPI.getUserViews(userId: SessionManager.main.currentLogin.user.id)
            .trackActivity(loading)
            .sink(receiveCompletion: { completion in
                self.handleAPIRequestError(completion: completion)
            }, receiveValue: { response in
                guard let items = response.items else { return }
                self.libraries = items.filter { self.supportedLibraries.contains($0.collectionType ?? "unknown") }
                self.libraries.forEach {
                    self.getRandomItemImageSource(with: nil, id: $0.id, key: $0.id ?? "")
                }
            })
            .store(in: &cancellables)
    }

    private func getRandomItemImageSource(with filters: [ItemFilter]?, id: String?, key: String) {
        ItemsAPI.getItemsByUserId(
            userId: SessionManager.main.currentLogin.user.id,
            limit: 3,
            recursive: true,
            parentId: id,
            includeItemTypes: [.movie, .series],
            filters: filters,
            sortBy: ["Random"]
        )
        .sink(receiveCompletion: { [weak self] completion in
            self?.handleAPIRequestError(completion: completion)
        }, receiveValue: { [weak self] response in
            guard let items = response.items else { return }
            let imageSources = items.map { $0.imageSource(.backdrop, maxWidth: 500) }
            self?.libraryImages[key] = imageSources
        })
        .store(in: &cancellables)
    }
}
