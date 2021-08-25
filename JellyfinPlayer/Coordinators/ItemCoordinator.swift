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

final class ItemCoordinator: NavigationCoordinatable {
    var navigationStack = NavigationStack()
    var viewModel: ItemViewModel

    init(viewModel: ItemViewModel) {
        self.viewModel = viewModel
    }

    enum Route: NavigationRoute {
        case item(viewModel: ItemViewModel)
        case library(viewModel: LibraryViewModel, title: String)
        case videoPlayer(item: BaseItemDto)
    }

    func resolveRoute(route: Route) -> Transition {
        switch route {
        case let .item(viewModel):
            return .push(ItemCoordinator(viewModel: viewModel).eraseToAnyCoordinatable())
        case let .library(viewModel, title):
            return .push(LibraryCoordinator(viewModel: viewModel, title: title).eraseToAnyCoordinatable())
        case let .videoPlayer(item):
            return .fullScreen(NavigationViewCoordinator(VideoPlayerCoordinator(item: item)).eraseToAnyCoordinatable())
        }
    }

    @ViewBuilder
    func start() -> some View {
        ItemView(viewModel: self.viewModel)
    }
}
