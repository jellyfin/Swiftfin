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
import WidgetKit

final class MainCoordinator: NavigationCoordinatable {
    var stack: NavigationStack<MainCoordinator>

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

        WidgetCenter.shared.reloadAllTimelines()
        UIScrollView.appearance().keyboardDismissMode = .onDrag

        // Back bar button item setup
        let backButtonBackgroundImage = UIImage(systemName: "chevron.backward.circle.fill")
        let barAppearance = UINavigationBar.appearance()
        barAppearance.backIndicatorImage = backButtonBackgroundImage
        barAppearance.backIndicatorTransitionMaskImage = backButtonBackgroundImage
        barAppearance.tintColor = UIColor(Color.jellyfinPurple)

        // Notification setup for state
        let nc = SwiftfinNotificationCenter.main
        nc.addObserver(self, selector: #selector(didLogIn), name: SwiftfinNotificationCenter.Keys.didSignIn, object: nil)
        nc.addObserver(self, selector: #selector(didLogOut), name: SwiftfinNotificationCenter.Keys.didSignOut, object: nil)
        nc.addObserver(self, selector: #selector(processDeepLink), name: SwiftfinNotificationCenter.Keys.processDeepLink, object: nil)
        nc.addObserver(self, selector: #selector(didChangeServerCurrentURI), name: SwiftfinNotificationCenter.Keys.didChangeServerCurrentURI, object: nil)
    }

    @objc func didLogIn() {
        LogManager.shared.log.info("Received `didSignIn` from SwiftfinNotificationCenter.")
        root(\.mainTab)
    }

    @objc func didLogOut() {
        LogManager.shared.log.info("Received `didSignOut` from SwiftfinNotificationCenter.")
        root(\.serverList)
    }

    @objc func processDeepLink(_ notification: Notification) {
        guard let deepLink = notification.object as? DeepLink else { return }
        if let coordinator = hasRoot(\.mainTab) {
            switch deepLink {
            case let .item(item):
                coordinator.focusFirst(\.home)
                    .child
                    .popToRoot()
                    .route(to: \.item, item)
            }
        }
    }
    
    @objc func didChangeServerCurrentURI(_ notification: Notification) {
        guard let newCurrentServerState = notification.object as? SwiftfinStore.State.Server else { fatalError("Need to have new current login state server") }
        guard SessionManager.main.currentLogin != nil else { return }
        if newCurrentServerState.id == SessionManager.main.currentLogin.server.id {
            SessionManager.main.loginUser(server: newCurrentServerState, user: SessionManager.main.currentLogin.user)
        }
    }
    
    func makeMainTab() -> MainTabCoordinator {
        MainTabCoordinator()
    }

    func makeServerList() -> NavigationViewCoordinator<ServerListCoordinator> {
        NavigationViewCoordinator(ServerListCoordinator())
    }
}
