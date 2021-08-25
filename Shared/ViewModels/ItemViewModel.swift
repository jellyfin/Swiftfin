//
/*
 * SwiftFin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import Foundation
import JellyfinAPI

class ItemViewModel: ViewModel {
    var id: String

    @Published var item: BaseItemDto?

    init(id: String) {
        self.id = id
        super.init()

        getRelatedItems()
    }

    func getRelatedItems() {
        UserLibraryAPI.getItem(userId: SessionManager.current.user.user_id!, itemId: id)
            .trackActivity(loading)
            .sink(receiveCompletion: { [weak self] completion in
                self?.handleAPIRequestError(completion: completion)
            }, receiveValue: { [weak self] response in
                self?.item = response
            })
            .store(in: &cancellables)
    }
}
