//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import FactoryKit
import SwiftUI

// TODO: move popup to router
//       - or, make tab view environment object

// TODO: fix weird tvOS icon rendering
struct MainTabView: View {

    @InjectedObject(\.deepLinkHandler)
    private var deepLinkHandler
    @Injected(\.userSessionManager)
    private var userSessionManager: UserSessionManager

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
    #endif

    private func routePendingDeepLink(_ deepLink: DeepLinkHandler.DeepLink?) {
        guard let deepLink else { return }

        Task { @MainActor in
            guard let currentSession = userSessionManager.currentSession else {
                throw UserSessionError.missingCurrentSession
            }

            let route = try await deepLinkHandler.route(for: deepLink, using: currentSession)
            await tabCoordinator.route(to: route)
        }
    }

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
        .onAppear {
            if let deepLink = deepLinkHandler.consumePendingDeepLink() {
                routePendingDeepLink(deepLink)
            }
        }
        .onReceive(deepLinkHandler.$pendingDeepLink.compactMap(\.self)) { _ in
            routePendingDeepLink(deepLinkHandler.consumePendingDeepLink())
        }
    }
}
