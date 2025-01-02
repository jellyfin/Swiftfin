//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Stinsen
import SwiftUI

// TODO: just have this coordinator wrap the content itself in a NavigationViewCoordinator instead

/// Basic coordinator to wrap a view for the purpose of being wrapped in a NavigationViewCoordinator
final class BasicNavigationViewCoordinator: NavigationCoordinatable {

    let stack = NavigationStack(initial: \BasicNavigationViewCoordinator.start)

    @Root
    var start = makeStart

    private let content: () -> any View

    init(@ViewBuilder _ content: @escaping () -> any View) {
        self.content = content
    }

    @ViewBuilder
    private func makeStart() -> some View {
        content().eraseToAnyView()
    }
}
