//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import SwiftUI

// TODO: move popup to router
//       - or, make tab view environment object

// TODO: fix weird tvOS icon rendering
struct MainTabView: View {

    @Default(.isLiquidGlassEnabled)
    private var isLiquidGlassEnabled

    #if os(iOS)
    @StateObject
    private var tabCoordinator = TabCoordinator {
        TabItem.home
        TabItem.media
        TabItem.search
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

    @ViewBuilder
    var body: some View {
        if isLiquidGlassEnabled, #available(iOS 26.0, *) {
            TabView {
                ForEach(tabCoordinator.tabs, id: \.item.id) { tabData in
                    if tabData.item.id == "search" {
                        Tab(role: .search) {
                            NavigationInjectionView(
                                coordinator: tabData.coordinator
                            ) {
                                tabData.item.content
                            }.environmentObject(tabCoordinator)
                                .environment(\.tabItemSelected, tabData.publisher).tag(tabData.item.id)
                        }
                    } else {
                        Tab(tabData.item.title, systemImage: tabData.item.systemImage) {
                            NavigationInjectionView(
                                coordinator: tabData.coordinator
                            ) {
                                tabData.item.content
                            }.environmentObject(tabCoordinator)
                                .environment(\.tabItemSelected, tabData.publisher).tag(tabData.item.id)
                        }
                    }
                }
            }.tabViewStyle(.sidebarAdaptable)
        } else {
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
        }
    }
}
