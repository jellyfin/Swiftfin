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

final class SearchCoordinator: NavigationCoordinatable {

    let stack = NavigationStack(initial: \SearchCoordinator.start)

    @Root
    var start = makeStart
    @Route(.modal)
    var item = makeItem
    @Route(.push)
    var library = makeLibrary
    #if !os(tvOS)
    @Route(.modal)
    var filter = makeFilter
    #endif

    #if os(tvOS)
    func makeItem(item: BaseItemDto) -> NavigationViewCoordinator<ItemCoordinator> {
        NavigationViewCoordinator(ItemCoordinator(item: item))
    }

    func makeLibrary(parameters: LibraryCoordinator.Parameters) -> NavigationViewCoordinator<LibraryCoordinator> {
        NavigationViewCoordinator(LibraryCoordinator(parameters: parameters))
    }
    #else
    func makeItem(item: BaseItemDto) -> ItemCoordinator {
        ItemCoordinator(item: item)
    }

    func makeLibrary(parameters: LibraryCoordinator.Parameters) -> LibraryCoordinator {
        LibraryCoordinator(parameters: parameters)
    }

    func makeFilter(parameters: FilterCoordinator.Parameters) -> NavigationViewCoordinator<FilterCoordinator> {
        NavigationViewCoordinator(FilterCoordinator(parameters: parameters))
    }
    #endif

    @ViewBuilder
    func makeStart() -> some View {
        SearchView(viewModel: .init())
    }
}
