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
    #if os(macOS)
    @State
    private var macSidebarVisible = true
    @State
    private var isPresentingVideoPlayer = false
    #endif

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

    #if os(macOS)
    /// Only content destinations belong in the sidebar: search and settings are
    /// presented from the window toolbar.
    private var macSidebarTabs: [TabCoordinator.TabData] {
        tabCoordinator.tabs.filter { tab in
            tab.item.id != TabItem.searchID && tab.item.id != TabItem.settingsID
        }
    }

    /// A toolbar control for a destination that has no sidebar row, styled to
    /// show whether that destination is the one currently presented.
    @ViewBuilder
    private func macToolbarTab(
        id: String,
        title: String,
        systemImage: String,
        key: KeyEquivalent
    ) -> some View {
        Toggle(
            isOn: Binding(
                get: { tabCoordinator.selectedTabID == id },
                set: { isSelected in
                    guard isSelected else { return }
                    tabCoordinator.selectedTabID = id
                }
            )
        ) {
            Label(title, systemImage: systemImage)
        }
        .toggleStyle(.button)
        .help(title)
        .keyboardShortcut(key, modifiers: .command)
    }

    @ViewBuilder
    private func macTabView() -> some View {
        HSplitView {
            if macSidebarVisible, !isPresentingVideoPlayer {
                List(selection: $tabCoordinator.selectedTabID) {
                    ForEach(macSidebarTabs, id: \.item.id) { tab in
                        Label(
                            tab.item.displayTitle,
                            systemImage: tab.item.systemImage
                        )
                        .tag(tab.item.id)
                    }
                }
                .listStyle(.sidebar)
                .scrollContentBackground(.hidden)
                .environment(\.defaultMinListRowHeight, 28)
                .frame(
                    minWidth: 200,
                    idealWidth: 220,
                    maxWidth: 320
                )
                .background(.bar)
            }

            if let tab = tabCoordinator.tabs.first(where: { $0.item.id == tabCoordinator.selectedTabID }) {
                NavigationInjectionView(coordinator: tab.coordinator) {
                    tab.item.content
                }
                .environmentObject(tabCoordinator)
                .environment(\.tabItemSelected, tab.publisher)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    macSidebarVisible.toggle()
                } label: {
                    Label(L10n.sidebar, systemImage: "sidebar.leading")
                }
                .help(L10n.sidebar)
            }

            ToolbarItem(placement: .primaryAction) {
                macToolbarTab(
                    id: TabItem.searchID,
                    title: L10n.search,
                    systemImage: "magnifyingglass",
                    key: "f"
                )
            }

            ToolbarItem(placement: .primaryAction) {
                macToolbarTab(
                    id: TabItem.settingsID,
                    title: L10n.settings,
                    systemImage: "gearshape",
                    key: ","
                )
            }
        }
        .toolbar(isPresentingVideoPlayer ? .hidden : .visible, for: .windowToolbar)
        .onPreferenceChange(VideoPlayerPresentedPreferenceKey.self) { isPresented in
            Task { @MainActor in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isPresentingVideoPlayer = isPresented
                }
            }
        }
    }
    #endif

    @ViewBuilder
    private func tabView() -> some View {
        #if os(macOS)
        macTabView()
        #else
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
        #endif
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
