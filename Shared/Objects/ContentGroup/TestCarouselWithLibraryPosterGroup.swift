//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct TestCarouselWithLibraryPosterGroup: ContentGroup {

    let id: String = "test-carousel"
    let displayTitle: String = ""
    let filters: ItemFilterCollection
    let viewModel: PagingLibraryViewModel<ItemLibrary>

    init(filters: ItemFilterCollection) {
        self.filters = filters
        self.viewModel = PagingLibraryViewModel(
            library: ItemLibrary(
                parent: TitledLibraryParent(displayTitle: L10n.items),
                filters: filters
            ),
            pageSize: 20
        )
    }

    func body(with viewModel: PagingLibraryViewModel<ItemLibrary>) -> some View {
        PosterHStackLibrarySection(
            viewModel: viewModel,
            group: PosterGroup(
                id: id,
                library: viewModel.library,
                posterDisplayType: .landscape,
                posterSize: .medium
            )
        )
    }
}
