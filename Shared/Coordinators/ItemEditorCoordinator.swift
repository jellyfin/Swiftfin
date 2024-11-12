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

final class ItemEditorCoordinator: ObservableObject, NavigationCoordinatable {

    let stack = NavigationStack(initial: \ItemEditorCoordinator.start)

    @Root
    var start = makeStart

    private let item: BaseItemDto

    init(item: BaseItemDto) {
        self.item = item
    }

    @ViewBuilder
    func makeStart() -> some View {
        ItemEditorView(item: item)
    }
}
