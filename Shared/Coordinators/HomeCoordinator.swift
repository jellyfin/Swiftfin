//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import Stinsen
import SwiftUI

final class HomeCoordinator: NavigationCoordinatable {

    let stack = NavigationStack(initial: \HomeCoordinator.start)

    @Root
    var start = makeStart

    #if os(tvOS)
    @Route(.modal)
    var item = makeItem
    @Route(.modal)
    var library = makeLibrary
    #else
    @Route(.push)
    var item = makeItem
    @Route(.push)
    var library = makeLibrary
    #endif

    #if os(tvOS)
    func makeItem(item: BaseItemDto) -> NavigationViewCoordinator<ItemCoordinator> {
        NavigationViewCoordinator(ItemCoordinator(item: item))
    }

    func makeLibrary(viewModel: PagingLibraryViewModel<BaseItemDto>) -> NavigationViewCoordinator<LibraryCoordinator<BaseItemDto>> {
        NavigationViewCoordinator(LibraryCoordinator<BaseItemDto>(viewModel: viewModel))
    }
    #else
    func makeItem(item: BaseItemDto) -> ItemCoordinator {
        ItemCoordinator(item: item)
    }

    func makeLibrary(viewModel: PagingLibraryViewModel<BaseItemDto>) -> LibraryCoordinator<BaseItemDto> {
        LibraryCoordinator(viewModel: viewModel)
    }
    #endif

    @ViewBuilder
    func makeStart() -> some View {
        HomeView()
    }
}
