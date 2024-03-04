//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import Foundation
import JellyfinAPI

final class MediaItemViewModel: ViewModel {

    @Published
    var imageSources: [ImageSource] = []

    let item: BaseItemDto

    private var randomItemTask: AnyCancellable?

    init(item: BaseItemDto) {
        self.item = item
        super.init()

        if item.collectionType == "favorites" {
            randomItemTask = Task { [weak self] in

                guard let sources = try? await self?.getRandomItemImageSource(traits: [.isFavorite]) else { return }
                guard let self else { return }

                await MainActor.run {
                    self.imageSources = sources
                }
            }
            .asAnyCancellable()
        } else if item.collectionType == "downloads" {
            imageSources = []
        } else if !Defaults[.Customization.Library.randomImage] || item.collectionType == "liveTV" {
            imageSources = [item.imageSource(.primary, maxWidth: 500)]
        } else {
            randomItemTask = Task { [weak self] in

                guard let sources = try? await self?.getRandomItemImageSource() else { return }
                guard let self else { return }

                await MainActor.run {
                    self.imageSources = sources
                }
            }
            .asAnyCancellable()
        }
    }

    private func getRandomItemImageSource(traits: [ItemTrait]? = nil) async throws -> [ImageSource] {
        let parameters = Paths.GetItemsParameters(
            userID: userSession.user.id,
            limit: 3,
            isRecursive: true,
            parentID: item.id,
            includeItemTypes: [.movie, .series],
            filters: traits,
            sortBy: [ItemSortBy.random.rawValue]
        )
        let request = Paths.getItems(parameters: parameters)
        let response = try await userSession.client.send(request)

        guard let item = response.value.items?.first else { return [] }

        return [item.imageSource(.backdrop, maxWidth: 500)]
    }
}

extension MediaItemViewModel: Equatable, Hashable {

    static func == (lhs: MediaItemViewModel, rhs: MediaItemViewModel) -> Bool {
        lhs.item == rhs.item
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(item.id)
    }
}
