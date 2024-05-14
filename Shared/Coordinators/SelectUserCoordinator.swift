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

final class SelectUserCoordinator: NavigationCoordinatable {

    struct SelectServerParameters {
        let selection: Binding<SelectUserServerSelection>
        let viewModel: SelectUserViewModel
    }

    let stack = NavigationStack(initial: \SelectUserCoordinator.start)

    @Root
    var start = makeStart

    @Route(.modal)
    var advancedSettings = makeAdvancedSettings
    @Route(.modal)
    var connectToServer = makeConnectToServer
    @Route(.modal)
    var editServer = makeEditServer
    @Route(.modal)
    var userSignIn = makeUserSignIn

    #if os(tvOS)
    @Route(.fullScreen)
    var selectServer = makeSelectServer
    #endif

    func makeAdvancedSettings() -> NavigationViewCoordinator<AppSettingsCoordinator> {
        NavigationViewCoordinator(AppSettingsCoordinator())
    }

    func makeConnectToServer() -> NavigationViewCoordinator<BasicNavigationViewCoordinator> {
        NavigationViewCoordinator {
            ConnectToServerView()
        }
    }

    func makeEditServer(server: ServerState) -> NavigationViewCoordinator<BasicNavigationViewCoordinator> {
        NavigationViewCoordinator {
            EditServerView(server: server)
                .environment(\.isEditing, true)
            #if os(iOS)
                .navigationBarCloseButton {
                    self.popLast()
                }
            #endif
        }
    }

    func makeUserSignIn(server: ServerState) -> NavigationViewCoordinator<UserSignInCoordinator> {
        NavigationViewCoordinator(UserSignInCoordinator(server: server))
    }

    #if os(tvOS)
    func makeSelectServer(parameters: SelectServerParameters) -> some View {
        SelectServerView(
            selection: parameters.selection,
            viewModel: parameters.viewModel
        )
    }
    #endif

    @ViewBuilder
    func makeStart() -> some View {
        SelectUserView()
    }
}
