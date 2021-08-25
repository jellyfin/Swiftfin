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

final class HomeCoordinator: NavigationCoordinatable {
    var navigationStack = NavigationStack()

    enum Route: NavigationRoute {
        case settings
        case library(viewModel: LibraryViewModel, title: String)
        case item(viewModel: ItemViewModel)
    }

    func resolveRoute(route: Route) -> Transition {
        switch route {
        case .settings:
            return .modal(NavigationViewCoordinator(SettingsCoordinator()).eraseToAnyCoordinatable())
        case let .library(viewModel, title):
            return .push(LibraryCoordinator(viewModel: viewModel, title: title).eraseToAnyCoordinatable())
        case let .item(viewModel):
            return .push(ItemCoordinator(viewModel: viewModel).eraseToAnyCoordinatable())
        }
    }

    @ViewBuilder
    func start() -> some View {
        HomeView()
    }
}
