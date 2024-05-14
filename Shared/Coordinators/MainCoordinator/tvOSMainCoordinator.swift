//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
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

    @Injected(LogManager.service)
    private var logger

    var stack: Stinsen.NavigationStack<MainCoordinator>

    @Root
    var mainTab = makeMainTab
    @Root
    var selectUser = makeSelectUser

    init() {

        if Container.userSession() != nil {
            stack = NavigationStack(initial: \MainCoordinator.mainTab)
        } else {
            stack = NavigationStack(initial: \MainCoordinator.selectUser)
        }

        ImageCache.shared.costLimit = 125 * 1024 * 1024 // 125MB memory
        DataLoader.sharedUrlCache.diskCapacity = 1000 * 1024 * 1024 // 1000MB disk

        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.label]

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

    func makeMainTab() -> MainTabCoordinator {
        MainTabCoordinator()
    }

    func makeSelectUser() -> NavigationViewCoordinator<SelectUserCoordinator> {
        NavigationViewCoordinator(SelectUserCoordinator())
    }
}
