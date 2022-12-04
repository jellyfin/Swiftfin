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

final class MediaItemViewModel: ViewModel {
    
    @Published
    var imageSources: [ImageSource]?
    
    let item: BaseItemDto
    
    init(item: BaseItemDto) {
        self.item = item
        super.init()
        
        if item.collectionType == "favorites" {
            getRandomItemImageSource(with: [.isFavorite])
        } else if !Defaults[.Customization.Library.randomImage] || item.collectionType == "liveTV" {
            self.imageSources = [item.imageSource(.primary, maxWidth: 500)]
        } else {
            getRandomItemImageSource(with: nil)
        }
    }
    
    private func getRandomItemImageSource(with filters: [ItemFilter]?) {
        ItemsAPI.getItemsByUserId(
            userId: SessionManager.main.currentLogin.user.id,
            limit: 3,
            recursive: true,
            parentId: item.id,
            includeItemTypes: [.movie, .series],
            filters: filters,
            sortBy: ["Random"]
        )
        .sink(receiveCompletion: { [weak self] completion in
            self?.handleAPIRequestError(completion: completion)
        }, receiveValue: { [weak self] response in
            guard let items = response.items else { return }
            self?.imageSources = items.map { $0.imageSource(.backdrop, maxWidth: 500) }
        })
        .store(in: &cancellables)
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
