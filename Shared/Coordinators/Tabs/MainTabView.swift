//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Factory
import JellyfinAPI
import SwiftUI

// TODO: move popup to router
//       - or, make tab view environment object

// TODO: fix weird tvOS icon rendering
struct MainTabView: View {

    #if os(iOS)
    @StateObject
    private var tabCoordinator = TabCoordinator {
        TabItem.home
        TabItem.search
        TabItem.media
    }
    #else
    @StateObject
    private var tabCoordinator = TabCoordinator {
        TabItem.home
        TabItem.library(
            title: L10n.tvShowsCapitalized,
            systemName: "tv",
            filters: .init(itemTypes: [.series])
        )
        TabItem.library(
            title: L10n.movies,
            systemName: "film",
            filters: .init(itemTypes: [.movie])
        )
        TabItem.search
        TabItem.media
        TabItem.settings
    }

    @StateObject
    private var topShelfRouter = TopShelfRouter.shared
    #endif

    @ViewBuilder
    var body: some View {
        TabView(selection: $tabCoordinator.selectedTabID) {
            ForEach(tabCoordinator.tabs, id: \.item.id) { tab in
                NavigationInjectionView(
                    coordinator: tab.coordinator
                ) {
                    tab.item.content
                }
                .environmentObject(tabCoordinator)
                .environment(\.tabItemSelected, tab.publisher)
                .tabItem {
                    Label(
                        tab.item.title,
                        systemImage: tab.item.systemImage
                    )
                    .labelStyle(tab.item.labelStyle)
                    .symbolRenderingMode(.monochrome)
                    .eraseToAnyView()
                }
                .tag(tab.item.id)
            }
        }
        #if os(tvOS)
        .task(id: topShelfRouter.pendingDeepLink) {
            await handlePendingTopShelfDeepLinkIfNeeded()
        }
        #endif
    }
}

#if os(tvOS)
extension MainTabView {

    @MainActor
    private func handlePendingTopShelfDeepLinkIfNeeded() async {
        guard let deepLink = topShelfRouter.pendingDeepLink else { return }
        guard let userSession = Container.shared.currentUserSession() else { return }

        guard userSession.user.id == deepLink.userID else {
            topShelfRouter.clear(deepLink)
            return
        }

        do {
            let request = Paths.getItem(
                itemID: deepLink.itemID,
                userID: userSession.user.id
            )
            let response = try await userSession.client.send(request)
            let item = response.value

            let route = route(for: deepLink.action, item: item)

            let coordinator = tabCoordinator.select(tabID: TabItem.home.id)
            coordinator?.reset()
            coordinator?.push(route)

            topShelfRouter.clear(deepLink)
        } catch {
            topShelfRouter.clear(deepLink)
        }
    }

    @MainActor
    private func route(
        for action: TopShelfDeepLink.Action,
        item: BaseItemDto
    ) -> NavigationRoute {
        switch action {
        case .display:
            .item(item: item)
        case .play:
            .videoPlayer(
                item: item,
                queue: item.type == .episode ? EpisodeMediaPlayerQueue(episode: item) : nil
            )
        }
    }
}
#endif
