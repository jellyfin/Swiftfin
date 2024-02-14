//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import JellyfinAPI
import Stinsen
import SwiftUI

final class LibraryCoordinator: NavigationCoordinatable {

    struct Parameters {
        let parent: (any LibraryParent)?
        let filters: ItemFilters

        init(
            parent: any LibraryParent,
            filters: ItemFilters
        ) {
            self.parent = parent
            self.filters = filters
        }

        init(filters: ItemFilters) {
            self.parent = nil
            self.filters = filters
        }
    }

    let stack = NavigationStack(initial: \LibraryCoordinator.start)

    @Root
    var start = makeStart

    #if os(tvOS)
    @Route(.modal)
    var item = makeItem
    @Route(.push)
    var library = makeLibrary
    #else
    @Route(.push)
    var item = makeItem
    @Route(.push)
    var library = makeLibrary
//    @Route(.push)
//    var folderLibrary = makeFolderLibrary
    @Route(.modal)
    var filter = makeFilter
    #endif

    private let parameters: Parameters

    init(parameters: Parameters) {
        self.parameters = parameters
    }

    @ViewBuilder
    func makeStart() -> some View {
        if let parent = parameters.parent {
            if !parameters.filters.hasFilters, let id = parent.id, let storedFilters = Defaults[.libraryFilterStore][id] {
//                LibraryView(viewModel: LibraryViewModel(parent: parent, type: parameters.type, filters: storedFilters, saveFilters: true))
                Text("FIX ME")
            } else {
                LibraryView(parent: parent, filters: parameters.filters)
                
                
//                LibraryView(viewModel: LibraryViewModel(
//                    parent: parent,
//                    type: parameters.type,
//                    filters: parameters.filters,
//                    saveFilters: false
//                ))
            }
        } else {
            Text("FIX ME")
//            LibraryView(viewModel: LibraryViewModel(filters: parameters.filters, saveFilters: false))
        }
    }

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
    
//    func makeFolderLibrary() -> LibraryCoordinator {
//        LibraryCoordinator(parameters: .init(parent: <#T##LibraryParent#>, filters: <#T##ItemFilters#>))
//    }

    func makeFilter(parameters: FilterCoordinator.Parameters) -> NavigationViewCoordinator<FilterCoordinator> {
        NavigationViewCoordinator(FilterCoordinator(parameters: parameters))
    }
    #endif
}
