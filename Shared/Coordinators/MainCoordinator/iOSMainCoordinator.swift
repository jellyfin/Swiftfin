//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import Factory
import Foundation
import JellyfinAPI
import Nuke
import Stinsen
import SwiftUI
import WidgetKit

final class MainCoordinator: NavigationCoordinatable {

    @Injected(LogManager.service)
    private var logger

    var stack: Stinsen.NavigationStack<MainCoordinator>

    @Root
    var mainTab = makeMainTab
    @Root
    var serverList = makeServerList
    @Route(.fullScreen)
    var videoPlayer = makeVideoPlayer

    private var cancellables = Set<AnyCancellable>()

    init() {

        if Container.userSession().authenticated {
            stack = NavigationStack(initial: \MainCoordinator.mainTab)
        } else {
            stack = NavigationStack(initial: \MainCoordinator.serverList)
        }

        ImageCache.shared.costLimit = 125 * 1024 * 1024 // 125MB memory
        DataLoader.sharedUrlCache.diskCapacity = 1000 * 1024 * 1024 // 1000MB disk

        WidgetCenter.shared.reloadAllTimelines()
        UIScrollView.appearance().keyboardDismissMode = .onDrag

        // Notification setup for state
        Notifications[.didSignIn].subscribe(self, selector: #selector(didSignIn))
        Notifications[.didSignOut].subscribe(self, selector: #selector(didSignOut))
        Notifications[.processDeepLink].subscribe(self, selector: #selector(processDeepLink(_:)))
        Notifications[.didChangeServerCurrentURI].subscribe(self, selector: #selector(didChangeServerCurrentURI(_:)))
    }

    @objc
    func didSignIn() {
        logger.info("Received `didSignIn` from SwiftfinNotificationCenter.")
        root(\.mainTab)
    }

    @objc
    func didSignOut() {
        logger.info("Received `didSignOut` from SwiftfinNotificationCenter.")
        root(\.serverList)
    }

    @objc
    func processDeepLink(_ notification: Notification) {
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

    @objc
    func didChangeServerCurrentURI(_ notification: Notification) {
//        guard let newCurrentServerState = notification.object as? SwiftfinStore.State.Server
//        else { fatalError("Need to have new current login state server") }
//        guard SessionManager.main.currentLogin != nil else { return }
//        if newCurrentServerState.id == SessionManager.main.currentLogin.server.id {
//            SessionManager.main.signInUser(server: newCurrentServerState, user: SessionManager.main.currentLogin.user)
//        }
    }

    func makeMainTab() -> MainTabCoordinator {
        MainTabCoordinator()
    }

    func makeServerList() -> NavigationViewCoordinator<ServerListCoordinator> {
        NavigationViewCoordinator(ServerListCoordinator())
    }

    func makeVideoPlayer(manager: VideoPlayerManager) -> VideoPlayerCoordinator {
        VideoPlayerCoordinator(manager: manager)
    }
}
