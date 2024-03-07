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

    enum MediaType: Hashable {
        case downloads
        case favorites
        case liveTV
        case userView(BaseItemDto)
    }

    @Published
    var imageSources: [ImageSource] = []

    let mediaType: MediaType

    init(type: MediaType) {
        self.mediaType = type
        super.init()

//        if item.collectionType == "favorites" {
//            randomItemTask = Task { [weak self] in
//
//                guard let sources = try? await self?.getRandomItemImageSource(traits: [.isFavorite]) else { return }
//                guard let self else { return }
//
//                await MainActor.run {
//                    self.imageSources = sources
//                }
//            }
//            .asAnyCancellable()
//        } else if item.collectionType == "downloads" {
//            imageSources = []
//        } else if !Defaults[.Customization.Library.randomImage] || item.collectionType == "liveTV" {
//            imageSources = [item.imageSource(.primary, maxWidth: 500)]
//        } else {
//            randomItemTask = Task { [weak self] in
//
//                guard let sources = try? await self?.getRandomItemImageSource() else { return }
//                guard let self else { return }
//
//                await MainActor.run {
//                    self.imageSources = sources
//                }
//            }
//            .asAnyCancellable()
//        }
    }

    func setImageSources(randomImage: Bool) {
        switch mediaType {
        case .downloads:
            ()
        case .favorites:
            Task { [weak self] in
                guard let self else { return }

                let sources = try await randomItemImageSources(traits: [.isFavorite])

                await MainActor.run {
                    self.imageSources = sources
                }
            }
            .store(in: &cancellables)
        case .liveTV:
            ()
        case let .userView(item):
            Task { [weak self] in
                guard let self else { return }

                let sources = try await randomItemImageSources(parent: item)

                await MainActor.run {
                    self.imageSources = sources
                }
            }
            .store(in: &cancellables)
        }
    }

    private func randomItemImageSources(parent: BaseItemDto? = nil, traits: [ItemTrait]? = nil) async throws -> [ImageSource] {

        var parameters = Paths.GetItemsByUserIDParameters()
        parameters.limit = 3
        parameters.isRecursive = true
        parameters.parentID = parent?.id
        parameters.includeItemTypes = [.movie, .series, .boxSet]
        parameters.filters = traits
        parameters.sortBy = [ItemSortBy.random.rawValue]

        let request = Paths.getItemsByUserID(userID: userSession.user.id, parameters: parameters)
        let response = try await userSession.client.send(request)

        return (response.value.items ?? [])
            .map { $0.imageSource(.backdrop, maxWidth: 500) }
    }
}

extension MediaItemViewModel: Hashable {

    static func == (lhs: MediaItemViewModel, rhs: MediaItemViewModel) -> Bool {
        lhs.mediaType == rhs.mediaType
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(mediaType)
    }
}
