//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import Stinsen
import SwiftUI

final class MainTabCoordinator: TabCoordinatable {
    var child: TabChild

    @Default(.Customization.Home.homeLabels)
    var sectionLabels

    @Route(tabItem: makeHomeTab, onTapped: onHomeTapped)
    var home = makeHome
    @Route(tabItem: makeSearchTab, onTapped: onSearchTapped)
    var search = makeSearch
    @Route(tabItem: makeMediaTab, onTapped: onMediaTapped)
    var media = makeMedia

    init() {
        self.child = MainTabCoordinator.makeChild()
    }

    func makeHome() -> NavigationViewCoordinator<HomeCoordinator> {
        NavigationViewCoordinator(HomeCoordinator())
    }

    func onHomeTapped(isRepeat: Bool, coordinator: NavigationViewCoordinator<HomeCoordinator>) {
        if isRepeat {
            coordinator.child.popToRoot()
        }
    }

    @ViewBuilder
    func makeHomeTab(isActive: Bool) -> some View {
        makeTab(image: Image(systemName: "house"), title: L10n.home)
    }

    func makeSearch() -> NavigationViewCoordinator<SearchCoordinator> {
        NavigationViewCoordinator(SearchCoordinator())
    }

    func onSearchTapped(isRepeat: Bool, coordinator: NavigationViewCoordinator<SearchCoordinator>) {
        if isRepeat {
            coordinator.child.popToRoot()
        }
    }

    @ViewBuilder
    func makeSearchTab(isActive: Bool) -> some View {
        makeTab(image: Image(systemName: "magnifyingglass"), title: L10n.search)
    }

    func makeMedia() -> NavigationViewCoordinator<MediaCoordinator> {
        NavigationViewCoordinator(MediaCoordinator())
    }

    func onMediaTapped(isRepeat: Bool, coordinator: NavigationViewCoordinator<MediaCoordinator>) {
        if isRepeat {
            coordinator.child.popToRoot()
        }
    }

    @ViewBuilder
    func makeMediaTab(isActive: Bool) -> some View {
        makeTab(image: Image(systemName: "rectangle.stack.fill"), title: L10n.media)
    }

    @ViewBuilder
    func customize(_ view: AnyView) -> some View {
        view.onAppear {
            AppURLHandler.shared.appURLState = .allowed
            // TODO: todo
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                AppURLHandler.shared.processLaunchedURLIfNeeded()
            }
        }
    }

    func makeTab(image tabIcon: Image, title tabLabel: String, useTitle tabTitle: Bool = true) -> some View {
        HStack {
            tabIcon
                .accessibilityLabel(tabLabel.text)
            if sectionLabels && tabTitle {
                tabLabel.text
            }
        }
    }

    static func makeChild() -> TabChild {
        @Default(.Customization.Home.homeSections)
        var homeSections
        var activeSections: [AnyKeyPath]

        // Re-Add Home back to the Main Tabs if removed
        if homeSections.contains(MainTabTypes.home) {
            activeSections = homeSections.compactMap(\.keyPath)
        } else {
            activeSections = homeSections.compactMap(\.keyPath) + [\MainTabCoordinator.home]
        }
        return TabChild(startingItems: activeSections)
    }
}
