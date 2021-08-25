//
/*
 * SwiftFin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import Foundation
import Stinsen
import SwiftUI

final class SearchCoordinator: NavigationCoordinatable {
    var navigationStack = NavigationStack()
    var viewModel: LibrarySearchViewModel
    
    init(viewModel: LibrarySearchViewModel) {
        self.viewModel = viewModel
    }

    enum Route: NavigationRoute {}

    func resolveRoute(route: Route) -> Transition {}

    @ViewBuilder
    func start() -> some View {
        LibrarySearchView(viewModel: self.viewModel)
    }
}
