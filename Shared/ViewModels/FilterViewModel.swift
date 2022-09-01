//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import SwiftUI

final class FilterViewModel: ViewModel {

    @Published
    var allFilters: ItemFilters = .all
    @Published
    var currentFilters: ItemFilters

    let parent: LibraryParent?

    init(
        parent: LibraryParent?,
        currentFilters: ItemFilters
    ) {
        self.parent = parent
        self.currentFilters = currentFilters
        super.init()

        getQueryFilters()
    }

    private func getQueryFilters() {
        FilterAPI.getQueryFilters(
            userId: SessionManager.main.currentLogin.user.id,
            parentId: parent?.id
        )
        .sink(receiveCompletion: { [weak self] completion in
            self?.handleAPIRequestError(completion: completion)
        }, receiveValue: { [weak self] queryFilters in
            self?.allFilters.genres = queryFilters.genres?.map(\.filter) ?? []
            self?.allFilters.tags = queryFilters.tags?.map(\.filter) ?? []
        })
        .store(in: &cancellables)
    }
}
