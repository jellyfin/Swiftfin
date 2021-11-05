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

final class HomeCoordinator: NavigationCoordinatable {

    let stack = NavigationStack(initial: \HomeCoordinator.start)

    @Root var start = makeStart
    @Route(.modal) var settings = makeSettings
    @Route(.push) var library = makeLibrary
    @Route(.push) var item = makeItem
    @Route(.modal) var modalItem = makeModalItem
    @Route(.modal) var modalLibrary = makeModalLibrary

    func makeSettings() -> NavigationViewCoordinator<SettingsCoordinator> {
        NavigationViewCoordinator(SettingsCoordinator())
    }

    func makeLibrary(params: LibraryCoordinatorParams) -> LibraryCoordinator {
        LibraryCoordinator(viewModel: params.viewModel, title: params.title)
    }

    func makeItem(item: BaseItemDto) -> ItemCoordinator {
        ItemCoordinator(item: item)
    }

    func makeModalItem(item: BaseItemDto) -> NavigationViewCoordinator<ItemCoordinator> {
        return NavigationViewCoordinator(ItemCoordinator(item: item))
    }

    func makeModalLibrary(params: LibraryCoordinatorParams) -> NavigationViewCoordinator<LibraryCoordinator> {
        return NavigationViewCoordinator(LibraryCoordinator(viewModel: params.viewModel, title: params.title))
    }

    @ViewBuilder func makeStart() -> some View {
        HomeView()
    }
}
