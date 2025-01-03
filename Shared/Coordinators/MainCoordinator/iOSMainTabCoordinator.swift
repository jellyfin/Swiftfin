//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import Stinsen
import SwiftUI

final class MainTabCoordinator: TabCoordinatable {

    var child = TabChild(startingItems: [
        \MainTabCoordinator.home,
        \MainTabCoordinator.search,
        \MainTabCoordinator.media,
    ])

    @Route(tabItem: makeHomeTab, onTapped: onHomeTapped)
    var home = makeHome
    @Route(tabItem: makeSearchTab, onTapped: onSearchTapped)
    var search = makeSearch
    @Route(tabItem: makeMediaTab, onTapped: onMediaTapped)
    var media = makeMedia

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
        Image(systemName: "house")
        L10n.home.text
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
        Image(systemName: "magnifyingglass")
        L10n.search.text
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
        Image(systemName: "rectangle.stack.fill")
        L10n.media.text
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
}
