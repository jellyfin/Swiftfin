//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import FactoryKit
import JellyfinAPI
import SwiftUI

// TODO: fix weird tvOS icon rendering
struct MainTabView: View {

    #if os(tvOS)
    @Default(.Customization.tabBarPlacement)
    private var tabBarPlacement
    #endif

    @InjectedObject(\.userSessionManager)
    private var userSessionManager

    @StateObject
    private var tabCoordinator: TabCoordinator

    init() {
        _tabCoordinator = StateObject(wrappedValue: Self.defaultTabCoordinator)
    }

    private static var defaultTabCoordinator: TabCoordinator {
        #if os(iOS)
        TabCoordinator {
            TabItem.contentGroup(provider: DefaultContentGroupProvider())
            TabItem.search
            TabItem.media
        }
        #else
        TabCoordinator {
            TabItem.contentGroup(provider: DefaultContentGroupProvider())
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
    }

    private func routePendingDeepLink(_ deepLink: DeepLink?) {
        guard let deepLink else { return }

        Task { @MainActor in
            let route = deepLink.route()
            await tabCoordinator.route(to: route)
        }
    }

    @ViewBuilder
    private func tabView() -> some View {
        TabView(selection: $tabCoordinator.selectedTabID) {
            ForEach(tabCoordinator.tabs, id: \.item.id) { tab in
                Tab(
                    value: tab.item.id,
                    role: tab.item.id == TabItem.search.id ? .search : nil
                ) {
                    NavigationInjectionView(
                        coordinator: tab.coordinator
                    ) {
                        tab.item.content
                        #if os(iOS)
                            .if(tabCoordinator.tabs.first?.item.id == tab.item.id) { view in
                                view.topBarTrailing {
                                    FirstTabSettingsBarButton()
                                }
                            }
                        #endif
                    }
                    .environmentObject(tabCoordinator)
                    .environment(\.tabItemSelected, tab.publisher)
                } label: {
                    Label(
                        tab.item.displayTitle,
                        systemImage: tab.item.systemImage
                    )
                    .symbolRenderingMode(.monochrome)
                }
            }
        }
    }

    @ViewBuilder
    private func tabContent() -> some View {
        #if os(tvOS)
        switch tabBarPlacement {
        case .sidebar:
            tabView()
                .tabViewStyle(.sidebarAdaptable)
        case .tabBar:
            tabView()
                .tabViewStyle(.tabBarOnly)
        }
        #else
        tabView()
        #endif
    }

    var body: some View {
        tabContent()
            .onChange(of: userSessionManager.pendingDeepLink) {
                routePendingDeepLink(userSessionManager.consumePendingDeepLink())
            }
            .onReceive(userSessionManager.routePublisher) { route in
                Task { @MainActor in
                    await tabCoordinator.route(to: route)
                }
            }
        #if os(tvOS)
            .background(alignment: .top) {
                FocusedPosterCinematicBackgroundView()
            }
        #endif
    }
}

#if os(iOS)
private struct FirstTabSettingsBarButton: View {

    @Injected(\.currentUserSession)
    private var userSession

    @Router
    private var router

    var body: some View {
        if router.isRootOfPath,
           let userSession
        {
            SettingsBarButton(
                server: userSession.server,
                user: userSession.user
            ) {
                router.route(to: .settings)
            }
        }
    }
}
#endif
