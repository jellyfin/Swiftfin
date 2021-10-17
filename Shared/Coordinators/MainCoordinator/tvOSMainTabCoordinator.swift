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
         \MainTabCoordinator.allMedia,
         \MainTabCoordinator.settings
    ])
    
    @Route(tabItem: makeHomeTab) var home = makeHome
    @Route(tabItem: makeAllMediaTab) var allMedia = makeAllMedia
    @Route(tabItem: makeSettingsTab) var settings = makeSettings
    
    func makeHome() -> NavigationViewCoordinator<HomeCoordinator> {
        return NavigationViewCoordinator(HomeCoordinator())
    }
    
    @ViewBuilder func makeHomeTab(isActive: Bool) -> some View {
        HStack {
            Image(systemName: "house")
            Text("Home")
        }
    }

    func makeAllMedia() -> NavigationViewCoordinator<LibraryListCoordinator> {
        return NavigationViewCoordinator(LibraryListCoordinator())
    }

    @ViewBuilder func makeAllMediaTab(isActive: Bool) -> some View {
        HStack {
            Image(systemName: "folder")
            Text("All Media")
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
