//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import Stinsen
import SwiftUI

final class OfflineCoordinator: NavigationCoordinatable {

    let stack = NavigationStack(initial: \OfflineCoordinator.start)

    @Root
    var start = makeStart

    @Route(.push)
    var item = makeItem
    @Route(.push)
    var library = makeLibrary

    var viewModel = OfflineViewModel()

    func makeItem(item: BaseItemDto) -> OfflineItemCoordinator {
        OfflineItemCoordinator(item: item, viewModel: viewModel)
    }

    func makeLibrary(viewModel: PagingLibraryViewModel<BaseItemDto>) -> LibraryCoordinator<BaseItemDto> {
        LibraryCoordinator(viewModel: viewModel)
    }

    @ViewBuilder
    func makeStart() -> some View {
        OfflineView(viewModel: viewModel)
    }
}
