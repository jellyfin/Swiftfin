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

final class LibraryListCoordinator: NavigationCoordinatable {
    var navigationStack = NavigationStack()

    enum Route: NavigationRoute {
        case search(viewModel: LibrarySearchViewModel)
        case library(viewModel: LibraryViewModel, title: String)
    }

    func resolveRoute(route: Route) -> Transition {
        switch route {
        case let .search(viewModel):
            return .push(SearchCoordinator(viewModel: viewModel).eraseToAnyCoordinatable())
        case let .library(viewModel, title):
            return .push(LibraryCoordinator(viewModel: viewModel, title: title).eraseToAnyCoordinatable())
        }
    }

    @ViewBuilder
    func start() -> some View {
        LibraryListView()
    }
}
