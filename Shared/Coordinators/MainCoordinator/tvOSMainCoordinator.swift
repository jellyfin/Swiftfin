//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Foundation
import Nuke
import Stinsen
import SwiftUI

final class MainCoordinator: NavigationCoordinatable {
    var stack = NavigationStack<MainCoordinator>(initial: \MainCoordinator.mainTab)

    @Root
    var mainTab = makeMainTab
    @Root
    var serverList = makeServerList
    @Root
    var liveTV = makeLiveTV

    init() {
        if SessionManager.main.currentLogin != nil {
            self.stack = NavigationStack(initial: \MainCoordinator.mainTab)
        } else {
            self.stack = NavigationStack(initial: \MainCoordinator.serverList)
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
        LogManager.log.info("Received `didSignIn` from NSNotificationCenter.")
        root(\.mainTab)
    }

    @objc
    func didSignOut() {
        LogManager.log.info("Received `didSignOut` from NSNotificationCenter.")
        root(\.serverList)
    }

    func makeMainTab() -> MainTabCoordinator {
        MainTabCoordinator()
    }

    func makeServerList() -> NavigationViewCoordinator<ServerListCoordinator> {
        NavigationViewCoordinator(ServerListCoordinator())
    }

    func makeLiveTV() -> LiveTVTabCoordinator {
        LiveTVTabCoordinator()
    }
}
