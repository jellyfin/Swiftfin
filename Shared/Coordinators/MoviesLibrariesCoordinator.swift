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
import Stinsen
import SwiftUI

final class MovieLibrariesCoordinator: NavigationCoordinatable {
    
    let stack = NavigationStack(initial: \MovieLibrariesCoordinator.start)

    @Root var start = makeStart
    @Route(.push) var library = makeLibrary

    let viewModel: MovieLibrariesViewModel
    let title: String

    init(viewModel: MovieLibrariesViewModel, title: String) {
        self.viewModel = viewModel
        self.title = title
    }

    @ViewBuilder func makeStart() -> some View {
        MovieLibrariesView(viewModel: self.viewModel, title: title)
    }

    func makeLibrary(library: BaseItemDto) -> LibraryCoordinator {
        LibraryCoordinator(viewModel: LibraryViewModel(parentID: library.id), title: library.title)
    }
}
