//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Factory
import SwiftUI

// TODO: move popup to router
//       - or, make tab view environment object

// TODO: fix weird tvOS icon rendering
struct MainTabView: View {

    @InjectedObject(\.deepLinkHandler)
    private var deepLinkHandler

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
        // Bruno tvOS IA: Search · Home · Movies · TV Shows · Collections · Kids · Settings.
        // Search (icon) leads, Settings (icon) trails; the app still opens on Home (see onAppear).
        TabItem.search
        TabItem.home
        TabItem.library(
            title: L10n.movies,
            systemName: "film",
            filters: .init(itemTypes: [.movie])
        )
        TabItem.library(
            title: L10n.tvShowsCapitalized,
            systemName: "tv",
            filters: .init(itemTypes: [.series])
        )
        TabItem.collections
        TabItem.kids
        TabItem.settings
    }
    #endif

    private func routePendingDeepLink() {
        guard let deepLink = deepLinkHandler.consumePendingDeepLink() else { return }

        Task { @MainActor in
            do {
                let route = try await deepLinkHandler.route(for: deepLink)
                tabCoordinator.route(to: route)
            } catch {
                // TODO: surface deep link failures in UI.
            }
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
            // Land on Home even though Search is the leading tab.
            if tabCoordinator.selectedTabID == nil {
                tabCoordinator.selectedTabID = "home"
            }
            routePendingDeepLink()
        }
        .onReceive(deepLinkHandler.$pendingDeepLink.compactMap(\.self)) { _ in
            routePendingDeepLink()
        }
    }
}
