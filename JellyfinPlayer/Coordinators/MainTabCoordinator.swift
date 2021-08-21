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
    lazy var children = TabChild(self, tabRoutes: [.home, .allMedia])

    enum Route: TabRoute {
        case home
        case allMedia
    }

    func tabItem(forTab tab: Int) -> some View {
        switch tab {
        case 0:
            Group {
                Text("Home")
                Image(systemName: "house")
            }
        case 1:
            Group {
                Text("Projects")
                Image(systemName: "folder")
            }
        default:
            fatalError()
        }
    }

    func resolveRoute(route: Route) -> AnyCoordinatable {
        switch route {
        case .home:
            return NavigationViewCoordinator(HomeCoordinator()).eraseToAnyCoordinatable()
        case .allMedia:
            return NavigationViewCoordinator(LibraryListCoordinator()).eraseToAnyCoordinatable()
        }
    }
}
