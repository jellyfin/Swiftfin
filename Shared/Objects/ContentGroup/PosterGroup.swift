//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct PosterGroup<Library: PagingLibrary>: _ContentGroup where Library.Element: LibraryElement {

    var displayTitle: String {
        library.parent.displayTitle
    }

    let id: String
    let library: Library
    let posterDisplayType: PosterDisplayType
    let posterSize: PosterDisplayType.Size
    let viewModel: PagingLibraryViewModel<Library>

    init(
        id: String = UUID().uuidString,
        library: Library,
        posterDisplayType: PosterDisplayType = .portrait,
        posterSize: PosterDisplayType.Size = .small
    ) {
        self.id = id
        self.library = library
        self.posterDisplayType = posterDisplayType
        self.posterSize = posterSize
        self.viewModel = .init(library: library, pageSize: 20)
    }

    @ViewBuilder
    func body(with viewModel: PagingLibraryViewModel<Library>) -> some View {
        PosterHStackLibrarySection(viewModel: viewModel, group: self)
    }
}
