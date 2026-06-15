//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct EpisodeGroup<Library: PagingLibrary>: ContentGroup where Library.Element == BaseItemDto {

    let displayTitle: String
    let id: String
    let library: Library
    let viewModel: PagingLibraryViewModel<Library>

    var _shouldBeResolved: Bool {
        viewModel.elements.isNotEmpty
    }

    init(library: Library) {
        self.displayTitle = library.parent.displayTitle
        self.id = UUID().uuidString
        self.library = library
        self.viewModel = .init(library: library, pageSize: 20)
    }

    @ViewBuilder
    func body(with viewModel: PagingLibraryViewModel<Library>) -> some View {
        PosterHStackLibrarySection(
            viewModel: viewModel,
            group: PosterGroup(
                id: id,
                library: library,
                posterDisplayType: .landscape,
                posterSize: .small
            )
        )
    }
}
