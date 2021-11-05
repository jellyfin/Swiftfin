//
 /* 
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import Foundation
import Stinsen
import SwiftUI

final class ServerListCoordinator: NavigationCoordinatable {

    let stack = NavigationStack(initial: \ServerListCoordinator.start)

    @Root var start = makeStart
    @Route(.push) var connectToServer = makeConnectToServer
    @Route(.push) var userList = makeUserList
    @Route(.modal) var basicAppSettings = makeBasicAppSettings

    func makeConnectToServer() -> ConnectToServerCoodinator {
        ConnectToServerCoodinator()
    }

    func makeUserList(server: SwiftfinStore.State.Server) -> UserListCoordinator {
        UserListCoordinator(viewModel: .init(server: server))
    }

    func makeBasicAppSettings() -> NavigationViewCoordinator<BasicAppSettingsCoordinator> {
        NavigationViewCoordinator(BasicAppSettingsCoordinator())
    }

    @ViewBuilder func makeStart() -> some View {
        ServerListView(viewModel: ServerListViewModel())
    }
}
