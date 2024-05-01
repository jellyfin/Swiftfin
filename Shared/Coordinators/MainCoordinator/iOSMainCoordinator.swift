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
    var userList = makeUserList

    @Route(.fullScreen)
    var videoPlayer = makeVideoPlayer
    @Route(.fullScreen)
    var liveVideoPlayer = makeLiveVideoPlayer

    private var cancellables = Set<AnyCancellable>()

    init() {

        if Container.userSession() != nil {
            stack = NavigationStack(initial: \MainCoordinator.mainTab)
        } else {
            stack = NavigationStack(initial: \MainCoordinator.userList)
        }

        ImageCache.shared.costLimit = 1000 * 1024 * 1024 // 125MB memory

        WidgetCenter.shared.reloadAllTimelines()
        UIScrollView.appearance().keyboardDismissMode = .onDrag

        // Notification setup for state
        Notifications[.didSignIn].subscribe(self, selector: #selector(didSignIn))
        Notifications[.didSignOut].subscribe(self, selector: #selector(didSignOut))
        Notifications[.processDeepLink].subscribe(self, selector: #selector(processDeepLink(_:)))
        Notifications[.didChangeCurrentServerURL].subscribe(self, selector: #selector(didChangeCurrentServerURL(_:)))
    }

    @objc
    func didSignIn() {
        logger.info("Signed in")
        root(\.mainTab)
    }

    @objc
    func didSignOut() {
        logger.info("Signed out")
        root(\.userList)
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
    func didChangeCurrentServerURL(_ notification: Notification) {

        guard Container.userSession() != nil else { return }

        Container.userSession.reset()
        Notifications[.didSignIn].post()
    }

    func makeMainTab() -> MainTabCoordinator {
        MainTabCoordinator()
    }

//    func makeServerList() -> NavigationViewCoordinator<ServerListCoordinator> {
//        NavigationViewCoordinator(ServerListCoordinator())
//    }

    func makeUserList() -> NavigationViewCoordinator<UserListCoordinator> {
        NavigationViewCoordinator(UserListCoordinator())
    }

    func makeVideoPlayer(manager: VideoPlayerManager) -> VideoPlayerCoordinator {
        VideoPlayerCoordinator(manager: manager)
    }

    func makeLiveVideoPlayer(manager: LiveVideoPlayerManager) -> LiveVideoPlayerCoordinator {
        LiveVideoPlayerCoordinator(manager: manager)
    }
}
