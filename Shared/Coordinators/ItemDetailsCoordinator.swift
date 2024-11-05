//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import Stinsen
import SwiftUI

final class ItemDetailsCoordinator: NavigationCoordinatable {

    let stack = NavigationStack(initial: \ItemDetailsCoordinator.start)

    let item: BaseItemDto

    @Root
    var start = makeStart

    init(item: BaseItemDto) {
        self.item = item
    }

    #if os(iOS)
    @Route(.push)
    var editMetadata = makeEditMetadata
    #endif

    #if os(iOS)
    @ViewBuilder
    func makeEditMetadata() -> some View {
        EditMetadataView(item: item)
    }
    #endif

    @ViewBuilder
    func makeStart() -> some View {
        ItemDetailsView(item: item)
    }
}
