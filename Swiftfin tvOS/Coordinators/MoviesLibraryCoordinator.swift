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

final class MoviesLibraryCoordinator: NavigationCoordinatable {
    
    let stack = NavigationStack(initial: \MoviesLibraryCoordinator.start)
    
    @Root
    var start = makeStart
    @Route(.modal)
    var item = makeItem
    @Route(.push)
    var library = makeLibrary
    
    @ViewBuilder
    func makeStart() -> some View {
        MoviesLibraryView(viewModel: .init())
    }
    
    func makeItem(item: BaseItemDto) -> NavigationViewCoordinator<ItemCoordinator> {
        NavigationViewCoordinator(ItemCoordinator(item: item))
    }

    func makeLibrary(parameters: LibraryCoordinator.Parameters) -> NavigationViewCoordinator<LibraryCoordinator> {
        NavigationViewCoordinator(LibraryCoordinator(parameters: parameters))
    }
}
