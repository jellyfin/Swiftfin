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

final class MetadataEditorCoordinator: NavigationCoordinatable {

    let stack = NavigationStack(initial: \MetadataEditorCoordinator.start)

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
    func makeEditItemMetadata() -> NavigationViewCoordinator<BasicNavigationViewCoordinator> {
        NavigationViewCoordinator { [self] in
            MetadataTextEditorView(item: baseItem)
        }
    }
    #endif

    @ViewBuilder
    func makeStart() -> some View {
        MetadataEditorView(viewModel: RefreshMetadataViewModel(item: baseItem))
    }
}
