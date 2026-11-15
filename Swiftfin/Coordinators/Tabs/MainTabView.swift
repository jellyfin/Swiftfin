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
@_spi(Advanced) import SwiftUIIntrospect

struct MainTabView: View {

    @InjectedObject(\.userSessionManager)
    private var userSessionManager

    @Default(.Experimental.layout)
    private var isLayoutExperimentEnabled

    @Default(.Customization.advancedLayout)
    private var isAdvancedLayoutEnabled

    @StoredValue(.User.layout)
    private var layout

    @State
    private var isSettingsPresented = false

    @StateObject
    private var tabCoordinator: TabCoordinator

    init() {
        _tabCoordinator = StateObject(wrappedValue: TabCoordinator(tabs: TabItem.defaultItems))
    }

    private func updateTabs() {
        tabCoordinator.updateTabs(TabItem.layoutItems(
            configuration: layout,
            advanced: isAdvancedLayoutEnabled,
            experimentEnabled: isLayoutExperimentEnabled
        ))
    }

    private func routePendingDeepLink(_ deepLink: DeepLink?) {
        guard let deepLink else { return }

        Task { @MainActor in
            let route = deepLink.route()
            await tabCoordinator.route(to: route)
        }
    }

    @ContentBuilder
    private func tabRoot(_ tab: TabCoordinator.TabData) -> some View {
        NavigationInjectionView(coordinator: tab.coordinator) {
            tab.item
                .content
                .withViewContext(.isTabRoot)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        if let userSession = userSessionManager.currentSession {
                            SettingsBarButton(userSession: userSession) {
                                isSettingsPresented = true
                            }
                        }
                    }
                }
        }
        .id(ObjectIdentifier(tab.coordinator))
        .environmentObject(tabCoordinator)
        .environment(\.tabItemSelected, tab.publisher)
    }

    @ContentBuilder
    private func tabView() -> some View {
        TabView(selection: $tabCoordinator.selectedTabID) {
            ForEach(tabCoordinator.tabs, id: \.item.id) { tab in
                Tab(value: tab.item.id) {
                    tabRoot(tab)
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

    @ContentBuilder
    var body: some View {
        tabView()
            .tabViewStyle(.sidebarAdaptable)
            .onChange(of: userSessionManager.pendingDeepLink) {
                routePendingDeepLink(userSessionManager.consumePendingDeepLink())
            }
            .onReceive(userSessionManager.routePublisher) { route in
                Task { @MainActor in
                    await tabCoordinator.route(to: route)
                }
            }
            .sheet(isPresented: $isSettingsPresented) {
                NavigationInjectionView(coordinator: NavigationCoordinator()) {
                    SettingsView()
                }
            }
            .onFirstAppear(perform: updateTabs)
            .onChange(of: isLayoutExperimentEnabled, updateTabs)
            .onChange(of: isAdvancedLayoutEnabled, updateTabs)
            .onChange(of: layout, updateTabs)
            .onChange(of: userSessionManager.currentSession?.userData.policy?.isAdministrator, updateTabs)
    }
}
