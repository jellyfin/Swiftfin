//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import SwiftUI

final class FilterViewModel: ViewModel {

    @Published
    var currentFilters: ItemFilters

    var allFilters: ItemFilters = .all
    let parent: (any LibraryParent)?

    init(
        parent: (any LibraryParent)?,
        currentFilters: ItemFilters
    ) {
        self.parent = parent
        self.currentFilters = currentFilters
        super.init()
    }

    func getGenres() async -> [ItemFilters.Filter] {
        let parameters = Paths.GetQueryFiltersParameters(
            userID: userSession.user.id,
            parentID: parent?.id as? String
        )
        let request = Paths.getQueryFilters(parameters: parameters)
        let response = try? await userSession.client.send(request)
        
        return response?.value.genres?
            .map(\.filter) ?? []
    }
}
