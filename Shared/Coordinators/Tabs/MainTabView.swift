//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Factory
import Logging
import SwiftUI
import UIKit

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
        TabItem.home
        TabItem.liveTV
        TabItem.requests
        TabItem.media
        TabItem.search
        TabItem.settings
    }

    // Non-Home tabs whose Back button should pop ONE page when deep in their own navigation stack, and
    // only switch to Home when already at their root (instead of always jumping straight to Home).
    private static let popThenHomeTabIDs: Set<String> = ["media", "requests"]
    #endif

    private func routePendingDeepLink() {
        // IMPORTANT: consume INSIDE the Task. `@Published` fires its publisher in `willSet` — before the
        // stored property is updated — so `.onReceive` runs while `pendingDeepLink` still holds the
        // PREVIOUS value. Reading it synchronously here opened the prior item (and the first tap opened
        // nothing). Deferring to the next main-actor hop lets `willSet` commit first, so we consume the
        // link the user actually tapped.
        Task { @MainActor in
            guard let deepLink = deepLinkHandler.consumePendingDeepLink() else { return }

            do {
                let route = try await deepLinkHandler.route(for: deepLink)
                // `route(to:)` selects the Home tab and pushes the item — so a Top Shelf tap lands on the
                // item no matter what screen the app was on.
                tabCoordinator.route(to: route)
            } catch {
                // TODO: surface deep link failures in UI.
                Logger.swiftfin().error(
                    "Failed to route deep link",
                    metadata: ["error": .stringConvertible(error.localizedDescription)]
                )
            }
        }
    }

    @ViewBuilder
    private var tabView: some View {
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
            routePendingDeepLink()
        }
        .onReceive(deepLinkHandler.$pendingDeepLink.compactMap(\.self)) { _ in
            routePendingDeepLink()
        }
    }

    var body: some View {
        tabView
        #if os(tvOS)
        // tvOS: pressing Select on the ALREADY-ACTIVE Home tab can't be observed through the
        // selection binding (the system doesn't re-emit it), so it would otherwise just descend
        // focus back into the content. This catcher collapses the Home stack to root on that press
        // — matching the long-press-Back behavior — but ONLY when focus is on the tab bar (so every
        // other Select press is left completely untouched). (Catchers live in `GuamaFlixTabBarCatchers`.)
            .background {
                TabBarReselectCatcher {
                    // `selectedTabID` is nil until the user switches tabs (tvOS TabView doesn't write
                    // the binding for the initial tab), so fall back to the first tab — the one shown
                    // on launch. Collapse the active tab's stack back to its root.
                    let activeID = tabCoordinator.selectedTabID ?? tabCoordinator.tabs.first?.item.id
                    guard let tab = tabCoordinator.tabs.first(where: { $0.item.id == activeID }),
                          tab.coordinator.path.isNotEmpty
                          || tab.coordinator.presentedSheet != nil
                          || tab.coordinator.presentedFullScreen != nil
                    else { return }

                    tab.coordinator.dismissToRoot()

                    // Tell the tab's content it was collapsed via a re-select (`isRepeat`) so it can
                    // restore focus — Home uses this to return focus to the poster the drill-down started
                    // from, instead of `defaultFocus` grabbing the spotlight/top row. On tvOS the
                    // `selectedTabID` binding isn't re-emitted for the active tab (that's why this catcher
                    // exists), so we send the same event its `didSet` would.
                    tab.publisher.send(.init(isRoot: true, isRepeat: true))
                }
            }
            // tvOS Menu/Back handling while focus is ON the tab bar (when focus is in content, the
            // `NavigationStack` pops on its own and this never fires):
            //   • Home, Media, Requests WITH pushed pages → pop ONE page. Focus stays on the tab bar; the
            //     revealed page is NOT auto-refocused (tvOS only restores last-focus on an IN-CONTENT Back —
            //     see the note in `handleMenu`).
            //   • Media / Requests at their ROOT → select Home (no app exit, focus stays on the tab bar).
            //   • Any OTHER non-Home tab (Live TV, Search, Settings) → select Home immediately.
            //   • Home tab at root → NOT intercepted, so Menu exits to the OS Home as tvOS requires.
            .background {
                TabBarBackCatcher(
                    canGoBack: {
                        let activeID = tabCoordinator.selectedTabID ?? tabCoordinator.tabs.first?.item.id
                        guard let tab = tabCoordinator.tabs.first(where: { $0.item.id == activeID }) else { return false }
                        // Home: intercept only to pop a pushed page; at the root let Menu exit to the OS.
                        if tab.item.id == "home" { return tab.coordinator.path.isNotEmpty }
                        // Every other tab: always intercept (Media/Requests pop a page when deep else go
                        // Home; the rest go straight Home).
                        return true
                    },
                    goBack: {
                        let activeID = tabCoordinator.selectedTabID ?? tabCoordinator.tabs.first?.item.id
                        guard let tab = tabCoordinator.tabs.first(where: { $0.item.id == activeID }) else { return }
                        // Home, Media, Requests: pop ONE page when deep in the stack.
                        if tab.item.id == "home" || Self.popThenHomeTabIDs.contains(tab.item.id) {
                            if tab.coordinator.path.isNotEmpty {
                                tab.coordinator.path.removeLast()
                                return
                            }
                            // At the tab's root: Home is never intercepted here (canGoBack == false), so
                            // only Media/Requests reach this — fall through to Home below.
                            if tab.item.id == "home" { return }
                        }
                        // Media/Requests at their root, and every other non-Home tab → select Home. Leaves
                        // every stack as-is and keeps focus on the tab bar (now on Home).
                        tabCoordinator.selectedTabID = "home"
                    }
                )
            }
        #endif
    }
}
