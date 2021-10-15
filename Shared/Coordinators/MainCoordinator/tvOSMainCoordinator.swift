//
 /* 
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import Foundation
import Nuke
import Stinsen
import SwiftUI

final class MainCoordinator: NavigationCoordinatable {
    var stack = NavigationStack<MainCoordinator>(initial: \MainCoordinator.mainTab)

    @Root var mainTab = makeMainTab
    @Root var serverList = makeServerList
    
    init() {
        if SessionManager.main.currentLogin != nil {
            self.stack = NavigationStack(initial: \MainCoordinator.mainTab)
        } else {
            self.stack = NavigationStack(initial: \MainCoordinator.serverList)
        }
        
        ImageCache.shared.costLimit = 125 * 1024 * 1024 // 125MB memory
        DataLoader.sharedUrlCache.diskCapacity = 1000 * 1024 * 1024 // 1000MB disk

        // Notification setup for state
        let nc = SwiftfinNotificationCenter.main
        nc.addObserver(self, selector: #selector(didLogIn), name: SwiftfinNotificationCenter.Keys.didSignIn, object: nil)
        nc.addObserver(self, selector: #selector(didLogOut), name: SwiftfinNotificationCenter.Keys.didSignOut, object: nil)
    }

    @objc func didLogIn() {
        LogManager.shared.log.info("Received `didSignIn` from NSNotificationCenter.")
        root(\.mainTab)
    }

    @objc func didLogOut() {
        LogManager.shared.log.info("Received `didSignOut` from NSNotificationCenter.")
        root(\.serverList)
    }

    func makeMainTab() -> MainTabCoordinator {
        MainTabCoordinator()
    }

    func makeServerList() -> NavigationViewCoordinator<ServerListCoordinator> {
        NavigationViewCoordinator(ServerListCoordinator())
    }
}
