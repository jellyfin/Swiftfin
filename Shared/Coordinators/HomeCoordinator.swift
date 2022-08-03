//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import Stinsen
import SwiftUI

final class HomeCoordinator: NavigationCoordinatable {

    let stack = NavigationStack(initial: \HomeCoordinator.start)

    @Root
    var start = makeStart
    @Route(.modal)
    var settings = makeSettings

    #if os(tvOS)
        @Route(.modal)
        var item = makeModalItem
        @Route(.modal)
        var library = makeModalLibrary
    #else
        @Route(.push)
        var item = makeItem
        @Route(.push)
        var library = makeLibrary
    #endif

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
        NavigationViewCoordinator(ItemCoordinator(item: item))
    }

    func makeModalLibrary(params: LibraryCoordinatorParams) -> NavigationViewCoordinator<LibraryCoordinator> {
        NavigationViewCoordinator(LibraryCoordinator(viewModel: params.viewModel, title: params.title))
    }

    @ViewBuilder
    func makeStart() -> some View {
        HomeView(viewModel: .init())
    }
}
