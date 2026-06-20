//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import FactoryKit
import SwiftUI

struct RootView: View {

    @StateObject
    private var rootCoordinator: RootCoordinator = .init()

    var body: some View {
        ZStack {
            switch rootCoordinator.state {
            case .initial:
                ProgressView()
            case .error:
                ErrorView(error: rootCoordinator.error ?? ErrorMessage(L10n.unknownError))
            case .ready:
                UserSessionRootView()
            }
        }
        .animation(.linear(duration: 0.1), value: rootCoordinator.state)
        .task {
            rootCoordinator.start()
        }
    }
}

struct UserSessionRootView: View {

    @Environment(\.localUserAuthenticationAction)
    private var authenticationAction

    @InjectedObject(\.userSessionManager)
    private var userSessionManager

    var body: some View {
        ZStack {
            switch userSessionManager.state {
            case .initial:
                ProgressView()
            case .signedOut:
                NavigationInjectionView(coordinator: .init()) {
                    SelectUserView()
                }
            case .signedIn:
                MainTabView()
            }
        }
        .animation(.linear(duration: 0.1), value: userSessionManager.state)
        .task {
            await userSessionManager.start()
        }
        .onOpenURL { url in
            Task {
                await userSessionManager.handleOpenURL(
                    url,
                    authenticationAction: authenticationAction
                )
            }
        }
    }
}
