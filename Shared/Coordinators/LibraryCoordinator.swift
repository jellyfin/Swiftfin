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

final class LibraryCoordinator: NavigationCoordinatable {

    struct Parameters {
        let parent: LibraryParent?
        let type: LibraryParentType
        let filters: ItemFilters

        init(
            parent: LibraryParent,
            type: LibraryParentType,
            filters: ItemFilters
        ) {
            self.parent = parent
            self.type = type
            self.filters = filters
        }

        init(filters: ItemFilters) {
            self.parent = nil
            self.type = .library
            self.filters = filters
        }
    }

    let stack = NavigationStack(initial: \LibraryCoordinator.start)

    @Root
    var start = makeStart

    #if os(tvOS)
    @Route(.modal)
    var item = makeItem
    #else
    @Route(.push)
    var item = makeItem
    @Route(.modal)
    var filter = makeFilter
    @Route(.push)
    var library = makeLibrary
    #endif

    private let parameters: Parameters

    init(parameters: Parameters) {
        self.parameters = parameters
    }

    @ViewBuilder
    func makeStart() -> some View {
        if let parent = parameters.parent {
            LibraryView(viewModel: .init(parent: parent, type: parameters.type, filters: parameters.filters))
        } else {
            LibraryView(viewModel: .init(filters: parameters.filters))
        }
    }

    #if os(tvOS)
    func makeItem(item: BaseItemDto) -> NavigationViewCoordinator<ItemCoordinator> {
        NavigationViewCoordinator(ItemCoordinator(item: item))
    }
    #else
    func makeItem(item: BaseItemDto) -> ItemCoordinator {
        ItemCoordinator(item: item)
    }

    func makeFilter(parameters: FilterCoordinator.Parameters) -> NavigationViewCoordinator<FilterCoordinator> {
        NavigationViewCoordinator(FilterCoordinator(parameters: parameters))
    }

    func makeLibrary(parameters: LibraryCoordinator.Parameters) -> LibraryCoordinator {
        LibraryCoordinator(parameters: parameters)
    }
    #endif
}
