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

final class LibraryCoordinator: NavigationCoordinatable {
    var navigationStack = NavigationStack()
    var viewModel: LibraryViewModel
    var title: String

    init(viewModel: LibraryViewModel, title: String) {
        self.viewModel = viewModel
        self.title = title
    }

    enum Route: NavigationRoute {
        case search(viewModel: LibrarySearchViewModel)
        case filter(filters: Binding<LibraryFilters>, enabledFilterType: [FilterType], parentId: String)
    }

    func resolveRoute(route: Route) -> Transition {
        switch route {
        case let .search(viewModel):
            return .push(SearchCoordinator(viewModel: viewModel).eraseToAnyCoordinatable())
        case let .filter(filters, enabledFilterType, parentId):
            return .modal(FilterCoordinator(filters: filters,
                                            enabledFilterType: enabledFilterType,
                                            parentId: parentId)
                    .eraseToAnyCoordinatable())
        }
    }

    @ViewBuilder
    func start() -> some View {
        LibraryView(viewModel: self.viewModel, title: title)
    }
}
