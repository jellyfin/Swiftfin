//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import JellyfinAPI
import Stinsen
import SwiftUI

final class MainTabCoordinator: TabCoordinatable {
    var child: TabChild

    @Default(.Customization.Home.homeLabels)
    var sectionLabels

    @Route(tabItem: makeHomeTab)
    var home = makeHome
    @Route(tabItem: makeBoxSetsTab)
    var boxSets = makeBoxSets
    @Route(tabItem: makeTvTab)
    var tvShows = makeTVShows
    @Route(tabItem: makeMoviesTab)
    var movies = makeMovies
    @Route(tabItem: makeSearchTab)
    var search = makeSearch
    @Route(tabItem: makeMediaTab)
    var media = makeMedia
    @Route(tabItem: makeSettingsTab)
    var settings = makeSettings

    init() {
        self.child = MainTabCoordinator.makeChild()
    }

    func makeHome() -> NavigationViewCoordinator<HomeCoordinator> {
        NavigationViewCoordinator(HomeCoordinator())
    }

    @ViewBuilder
    func makeHomeTab(isActive: Bool) -> some View {
        makeTab(image: MainTabTypes.home.displayIcon, title: MainTabTypes.home.displayTitle)
    }

    func makeBoxSets() -> NavigationViewCoordinator<LibraryCoordinator<BaseItemDto>> {
        let viewModel = ItemTypeLibraryViewModel(itemTypes: [.boxSet])
        return NavigationViewCoordinator(LibraryCoordinator(viewModel: viewModel))
    }

    @ViewBuilder
    func makeBoxSetsTab(isActive: Bool) -> some View {
        makeTab(image: MainTabTypes.boxSets.displayIcon, title: MainTabTypes.boxSets.displayTitle)
    }

    func makeTVShows() -> NavigationViewCoordinator<LibraryCoordinator<BaseItemDto>> {
        let viewModel = ItemTypeLibraryViewModel(itemTypes: [.series])
        return NavigationViewCoordinator(LibraryCoordinator(viewModel: viewModel))
    }

    @ViewBuilder
    func makeTvTab(isActive: Bool) -> some View {
        makeTab(image: MainTabTypes.tvShows.displayIcon, title: MainTabTypes.tvShows.displayTitle)
    }

    func makeMovies() -> NavigationViewCoordinator<LibraryCoordinator<BaseItemDto>> {
        let viewModel = ItemTypeLibraryViewModel(itemTypes: [.movie])
        return NavigationViewCoordinator(LibraryCoordinator(viewModel: viewModel))
    }

    @ViewBuilder
    func makeMoviesTab(isActive: Bool) -> some View {
        makeTab(image: MainTabTypes.movies.displayIcon, title: MainTabTypes.movies.displayTitle)
    }

    func makeSearch() -> VideoPlayerWrapperCoordinator {
        VideoPlayerWrapperCoordinator {
            SearchCoordinator()
                .view()
        }
    }

    @ViewBuilder
    func makeSearchTab(isActive: Bool) -> some View {
        makeTab(image: MainTabTypes.search.displayIcon, title: MainTabTypes.search.displayTitle)
    }

    func makeMedia() -> NavigationViewCoordinator<MediaCoordinator> {
        NavigationViewCoordinator(MediaCoordinator())
    }

    @ViewBuilder
    func makeMediaTab(isActive: Bool) -> some View {
        makeTab(image: MainTabTypes.media.displayIcon, title: MainTabTypes.media.displayTitle)
    }

    func makeSettings() -> NavigationViewCoordinator<SettingsCoordinator> {
        NavigationViewCoordinator(SettingsCoordinator())
    }

    @ViewBuilder
    func makeSettingsTab(isActive: Bool) -> some View {
        makeTab(image: MainTabTypes.settings.displayIcon, title: MainTabTypes.settings.displayTitle, useTitle: false)
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

        // Re-Add Settings back to the Main Tabs if removed
        if homeSections.contains(MainTabTypes.settings) {
            activeSections = homeSections.compactMap(\.keyPath)
        } else {
            activeSections = homeSections.compactMap(\.keyPath) + [\MainTabCoordinator.settings]
        }
        return TabChild(startingItems: activeSections)
    }
}
