//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import Stinsen
import SwiftUI

final class MainTabCoordinator: TabCoordinatable {

    var child = TabChild(startingItems: [
        \MainTabCoordinator.home,
        \MainTabCoordinator.tvShows,
        \MainTabCoordinator.movies,
        \MainTabCoordinator.search,
        \MainTabCoordinator.media,
        \MainTabCoordinator.settings,
    ])

    @Route(tabItem: makeHomeTab)
    var home = makeHome
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

    func makeHome() -> NavigationViewCoordinator<HomeCoordinator> {
        NavigationViewCoordinator(HomeCoordinator())
    }

    @ViewBuilder
    func makeHomeTab(isActive: Bool) -> some View {
        HStack {
            Image(systemName: "house")
            L10n.home.text
        }
    }

    func makeTVShows() -> NavigationViewCoordinator<LibraryCoordinator<BaseItemDto>> {
        let viewModel = ItemLibraryViewModel(
            filters: .init(itemTypes: [.series])
        )
        return NavigationViewCoordinator(LibraryCoordinator(viewModel: viewModel))
    }

    @ViewBuilder
    func makeTvTab(isActive: Bool) -> some View {
        HStack {
            Image(systemName: "tv")
                .symbolRenderingMode(.monochrome)
            L10n.tvShows.text
        }
    }

    func makeMovies() -> NavigationViewCoordinator<LibraryCoordinator<BaseItemDto>> {
        let viewModel = ItemLibraryViewModel(
            filters: .init(itemTypes: [.movie])
        )
        return NavigationViewCoordinator(LibraryCoordinator(viewModel: viewModel))
    }

    @ViewBuilder
    func makeMoviesTab(isActive: Bool) -> some View {
        HStack {
            Image(systemName: "film")
            L10n.movies.text
        }
    }

    // TODO: does this cause issues?
    func makeSearch() -> VideoPlayerWrapperCoordinator {
        VideoPlayerWrapperCoordinator {
            SearchCoordinator()
                .view()
        }
    }

    @ViewBuilder
    func makeSearchTab(isActive: Bool) -> some View {
        HStack {
            Image(systemName: "magnifyingglass")
            L10n.search.text
        }
    }

    func makeMedia() -> NavigationViewCoordinator<MediaCoordinator> {
        NavigationViewCoordinator(MediaCoordinator())
    }

    @ViewBuilder
    func makeMediaTab(isActive: Bool) -> some View {
        HStack {
            Image(systemName: "rectangle.stack")
            L10n.media.text
        }
    }

    func makeSettings() -> NavigationViewCoordinator<SettingsCoordinator> {
        NavigationViewCoordinator(SettingsCoordinator())
    }

    @ViewBuilder
    func makeSettingsTab(isActive: Bool) -> some View {
        Image(systemName: "gearshape.fill")
            .accessibilityLabel(L10n.settings)
    }
}
