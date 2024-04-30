//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation
import Stinsen
import SwiftUI

final class UserSignInCoordinator: NavigationCoordinatable {

    let stack = NavigationStack(initial: \UserSignInCoordinator.start)

    @Root
    var start = makeStart

    #if os(iOS)
    @Route(.modal)
    var quickConnect = makeQuickConnect
    #endif

    private let server: ServerState

    init(server: ServerState) {
        self.server = server
    }

    #if os(iOS)
    func makeQuickConnect() -> NavigationViewCoordinator<BasicNavigationViewCoordinator> {
        NavigationViewCoordinator {
            QuickConnectView(server: self.server)
        }
    }
    #endif

    @ViewBuilder
    func makeStart() -> some View {
        UserSignInView(server: server)
    }
}
