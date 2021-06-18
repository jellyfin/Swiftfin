//
 /* 
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import Foundation
import Foundation
import JellyfinAPI

class DetailItemViewModel: ViewModel {
    @Published
    var item: BaseItemDto

    @Published
    var isWatched = false
    @Published
    var isFavorited = false

    init(item: BaseItemDto) {
        self.item = item
        isFavorited = item.userData?.isFavorite ?? false
        isWatched = item.userData?.played ?? false
        super.init()
    }

    func updateWatchState() {
        if isWatched {
            PlaystateAPI.markUnplayedItem(userId: SessionManager.current.user.user_id!, itemId: item.id!)
                .trackActivity(loading)
                .sink(receiveCompletion: { [weak self] completion in
                    self?.handleAPIRequestCompletion(completion: completion)
                }, receiveValue: { [weak self] _ in
                    self?.isWatched = false
                })
                .store(in: &cancellables)
        } else {
            PlaystateAPI.markPlayedItem(userId: SessionManager.current.user.user_id!, itemId: item.id!)
                .trackActivity(loading)
                .sink(receiveCompletion: { [weak self] completion in
                    self?.handleAPIRequestCompletion(completion: completion)
                }, receiveValue: { [weak self] _ in
                    self?.isWatched = true
                })
                .store(in: &cancellables)
        }
    }

    func updateFavoriteState() {
        if isFavorited {
            UserLibraryAPI.unmarkFavoriteItem(userId: SessionManager.current.user.user_id!, itemId: item.id!)
                .trackActivity(loading)
                .sink(receiveCompletion: { [weak self] completion in
                    self?.handleAPIRequestCompletion(completion: completion)
                }, receiveValue: { [weak self] _ in
                    self?.isFavorited = false
                })
                .store(in: &cancellables)
        } else {
            UserLibraryAPI.markFavoriteItem(userId: SessionManager.current.user.user_id!, itemId: item.id!)
                .trackActivity(loading)
                .sink(receiveCompletion: { [weak self] completion in
                    self?.handleAPIRequestCompletion(completion: completion)
                }, receiveValue: { [weak self] _ in
                    self?.isFavorited = true
                })
                .store(in: &cancellables)
        }
    }
}
