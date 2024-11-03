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

final class BaseItemEditorCoordinator: NavigationCoordinatable {

    let stack = NavigationStack(initial: \BaseItemEditorCoordinator.start)

    @Root
    var start = makeStart

    #if os(iOS)
    @Route(.modal)
    var editItemMetadata = makeEditItemMetadata
    #endif

    private let baseItem: BaseItemDto

    init(baseItem: BaseItemDto) {
        self.baseItem = baseItem
    }

    #if os(iOS)
    @ViewBuilder
    func makeEditItemMetadata() -> some View {
        MetadataEditorView(item: baseItem)
    }
    #endif

    @ViewBuilder
    func makeStart() -> some View {
        BaseItemOptionsView(viewModel: RefreshMetadataViewModel(item: baseItem))
    }
}
