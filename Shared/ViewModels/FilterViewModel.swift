//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
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
        Task {
            let parameters = Paths.GetQueryFiltersParameters(
                userID: userSession.user.id,
                parentID: parent?.id
            )
            let request = Paths.getQueryFilters(parameters: parameters)
            let response = try await userSession.client.send(request)

            await MainActor.run {
                allFilters.genres = response.value.genres?.map(\.filter) ?? []
            }
        }
    }
}
