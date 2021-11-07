//
 /* 
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import Foundation
import SwiftUI
import Stinsen

final class MainTabCoordinator: TabCoordinatable {
    var child = TabChild(startingItems: [
        \MainTabCoordinator.home,
         \MainTabCoordinator.tv,
         \MainTabCoordinator.movies,
         \MainTabCoordinator.other,
         \MainTabCoordinator.settings
    ])
    
    @Route(tabItem: makeHomeTab) var home = makeHome
    @Route(tabItem: makeTvTab) var tv = makeTv
    @Route(tabItem: makeMoviesTab) var movies = makeMovies
    @Route(tabItem: makeOtherTab) var other = makeOther
    @Route(tabItem: makeSettingsTab) var settings = makeSettings
    
    func makeHome() -> NavigationViewCoordinator<HomeCoordinator> {
        return NavigationViewCoordinator(HomeCoordinator())
    }
    
    @ViewBuilder func makeHomeTab(isActive: Bool) -> some View {
        HStack {
            Image(systemName: "house")
            L10n.home.text
        }
    }
    
    func makeTv() -> NavigationViewCoordinator<TVLibrariesCoordinator> {
        return NavigationViewCoordinator(TVLibrariesCoordinator(viewModel: TVLibrariesViewModel(), title: "TV Shows"))
    }

    @ViewBuilder func makeTvTab(isActive: Bool) -> some View {
        HStack {
            Image(systemName: "tv")
            Text("TV Shows")
        }
    }
    
    func makeMovies() -> NavigationViewCoordinator<MovieLibrariesCoordinator> {
        return NavigationViewCoordinator(MovieLibrariesCoordinator(viewModel: MovieLibrariesViewModel(), title: "Movies"))
    }

    @ViewBuilder func makeMoviesTab(isActive: Bool) -> some View {
        HStack {
            Image(systemName: "film")
            Text("Movies")
        }
    }

    func makeOther() -> NavigationViewCoordinator<LibraryListCoordinator> {
        return NavigationViewCoordinator(LibraryListCoordinator())
    }

    @ViewBuilder func makeOtherTab(isActive: Bool) -> some View {
        HStack {
            Image(systemName: "folder")
            Text("Other")
        }
    }
    
    func makeSettings() -> NavigationViewCoordinator<SettingsCoordinator> {
        return NavigationViewCoordinator(SettingsCoordinator())
    }
    
    @ViewBuilder func makeSettingsTab(isActive: Bool) -> some View {
        HStack {
            Image(systemName: "gearshape.fill")
            Text("Settings")
        }
    }
}
