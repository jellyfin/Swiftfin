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

// TODO: See if this and LibraryCoordinator can be merged,
//       along with all corresponding views
final class BasicLibraryCoordinator: NavigationCoordinatable {

    struct Parameters {
        let title: String?
        let viewModel: PagingLibraryViewModel
    }

    let stack = NavigationStack(initial: \BasicLibraryCoordinator.start)

    @Root
    var start = makeStart
    @Route(.push)
    var item = makeItem
    @Route(.push)
    var library = makeLibrary

    private let parameters: Parameters

    init(parameters: Parameters) {
        self.parameters = parameters
    }

    @ViewBuilder
    func makeStart() -> some View {
        BasicLibraryView(viewModel: parameters.viewModel)
        #if !os(tvOS)
            .if(parameters.title != nil) { view in
                view.navigationTitle(parameters.title ?? .emptyDash)
            }
        #endif
    }

    func makeItem(item: BaseItemDto) -> NavigationViewCoordinator<ItemCoordinator> {
        NavigationViewCoordinator(ItemCoordinator(item: item))
    }

    func makeLibrary(parameters: LibraryCoordinator.Parameters) -> NavigationViewCoordinator<LibraryCoordinator> {
        NavigationViewCoordinator(LibraryCoordinator(parameters: parameters))
    }
}
