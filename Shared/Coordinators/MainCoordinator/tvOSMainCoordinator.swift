//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Factory
import Foundation
import Nuke
import Stinsen
import SwiftUI

// TODO: clean up like iOS
//       - move some things to App
// TODO: server check flow

final class MainCoordinator: NavigationCoordinatable {

    @Injected(\.logService)
    private var logger

    var stack: Stinsen.NavigationStack<MainCoordinator>

    @Root
    var loading = makeLoading
    @Root
    var mainTab = makeMainTab
    @Root
    var selectUser = makeSelectUser

    init() {

        stack = NavigationStack(initial: \.loading)

        Task {
            do {
                try await SwiftfinStore.setupDataStack()

                if Container.shared.currentUserSession() != nil {
                    await MainActor.run {
                        withAnimation(.linear(duration: 0.1)) {
                            let _ = root(\.mainTab)
                        }
                    }
                } else {
                    await MainActor.run {
                        withAnimation(.linear(duration: 0.1)) {
                            let _ = root(\.selectUser)
                        }
                    }
                }

            } catch {
                await MainActor.run {
                    logger.critical("\(error.localizedDescription)")
                    Notifications[.didFailMigration].post()
                }
            }
        }

        // Notification setup for state
        Notifications[.didSignIn].subscribe(self, selector: #selector(didSignIn))
        Notifications[.didSignOut].subscribe(self, selector: #selector(didSignOut))
    }

    @objc
    func didSignIn() {
        logger.info("Signed in")

        withAnimation(.linear(duration: 0.1)) {
            let _ = root(\.mainTab)
        }
    }

    @objc
    func didSignOut() {
        logger.info("Signed out")

        withAnimation(.linear(duration: 0.1)) {
            let _ = root(\.selectUser)
        }
    }

    func makeLoading() -> NavigationViewCoordinator<BasicNavigationViewCoordinator> {
        NavigationViewCoordinator {
            AppLoadingView()
        }
    }

    func makeMainTab() -> MainTabCoordinator {
        MainTabCoordinator()
    }

    func makeSelectUser() -> NavigationViewCoordinator<SelectUserCoordinator> {
        NavigationViewCoordinator(SelectUserCoordinator())
    }
}
