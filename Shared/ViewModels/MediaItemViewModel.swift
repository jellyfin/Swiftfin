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

final class MediaItemViewModel: ViewModel {

    @Published
    var imageSources: [ImageSource]?

    let item: BaseItemDto

    init(item: BaseItemDto) {
        self.item = item
        super.init()

        if item.collectionType == "favorites" {
            getRandomItemImageSource(with: [.isFavorite])
        } else if item.collectionType == "downloads" {
            imageSources = nil
        } else if !Defaults[.Customization.Library.randomImage] || item.collectionType == "liveTV" {
            imageSources = [item.imageSource(.primary, maxWidth: 500)]
        } else {
            getRandomItemImageSource(with: nil)
        }
    }

    private func getRandomItemImageSource(with filters: [ItemFilter]?) {
        Task {
            let parameters = Paths.GetItemsParameters(
                userID: userSession.user.id,
                limit: 1,
                isRecursive: true,
                parentID: item.id,
                includeItemTypes: [.movie, .series],
                filters: filters,
                sortBy: ["Random"]
            )
            let request = Paths.getItems(parameters: parameters)
            let response = try await userSession.client.send(request)

            guard let item = response.value.items?.first else { return }

            await MainActor.run {
                imageSources = [item.imageSource(.backdrop, maxWidth: 500)]
            }
        }
    }
}

extension MediaItemViewModel: Equatable {

    static func == (lhs: MediaItemViewModel, rhs: MediaItemViewModel) -> Bool {
        lhs.item == rhs.item
    }
}

extension MediaItemViewModel: Hashable {

    func hash(into hasher: inout Hasher) {
        hasher.combine(item)
    }
}
