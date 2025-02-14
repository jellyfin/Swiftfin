//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import Factory
import Foundation
import JellyfinAPI
import Nuke
import Stinsen
import SwiftUI

// TODO: could possibly clean up
//       - only go to loading if migrations necessary
//       - account for other migrations (Defaults)

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
    @Root
    var serverCheck = makeServerCheck

    @Route(.fullScreen)
    var liveVideoPlayer = makeLiveVideoPlayer
    @Route(.modal)
    var settings = makeSettings
    @Route(.fullScreen)
    var videoPlayer = makeVideoPlayer

    init() {

        stack = NavigationStack(initial: \.loading)

        Task {
            do {
                try await SwiftfinStore.setupDataStack()

                if Container.shared.currentUserSession() != nil, !Defaults[.signOutOnClose] {
                    await MainActor.run {
                        withAnimation(.linear(duration: 0.1)) {
                            let _ = root(\.serverCheck)
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

        // TODO: move these to the App instead?

        // Notification setup for state
        Notifications[.didSignIn].subscribe(self, selector: #selector(didSignIn))
        Notifications[.didSignOut].subscribe(self, selector: #selector(didSignOut))
        Notifications[.processDeepLink].subscribe(self, selector: #selector(processDeepLink(_:)))
        Notifications[.didChangeCurrentServerURL].subscribe(self, selector: #selector(didChangeCurrentServerURL(_:)))
    }

    private func didFinishMigration() {}

    @objc
    func didSignIn() {
        logger.info("Signed in")

        withAnimation(.linear(duration: 0.1)) {
            let _ = root(\.serverCheck)
        }
    }

    @objc
    func didSignOut() {
        logger.info("Signed out")

        withAnimation(.linear(duration: 0.1)) {
            let _ = root(\.selectUser)
        }
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

        guard Container.shared.currentUserSession() != nil else { return }

        Container.shared.currentUserSession.reset()
        Notifications[.didSignIn].post()
    }

    func makeLoading() -> NavigationViewCoordinator<BasicNavigationViewCoordinator> {
        NavigationViewCoordinator {
            AppLoadingView()
        }
    }

    func makeSettings() -> NavigationViewCoordinator<SettingsCoordinator> {
        NavigationViewCoordinator(SettingsCoordinator())
    }

    func makeMainTab() -> MainTabCoordinator {
        MainTabCoordinator()
    }

    func makeSelectUser() -> NavigationViewCoordinator<SelectUserCoordinator> {
        NavigationViewCoordinator(SelectUserCoordinator())
    }

    func makeServerCheck() -> NavigationViewCoordinator<BasicNavigationViewCoordinator> {
        NavigationViewCoordinator {
            ServerCheckView()
        }
    }

    func makeVideoPlayer(manager: VideoPlayerManager) -> VideoPlayerCoordinator {
        VideoPlayerCoordinator(manager: manager)
    }

    func makeLiveVideoPlayer(manager: LiveVideoPlayerManager) -> LiveVideoPlayerCoordinator {
        LiveVideoPlayerCoordinator(manager: manager)
    }
}
