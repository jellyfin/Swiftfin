//
/*
 * SwiftFin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import Foundation
import Stinsen
import SwiftUI

final class MainCoordinator: ViewCoordinatable {
    var children = ViewChild()

    enum Route: ViewRoute {
        case mainTab
        case connectToServer
    }

    func resolveRoute(route: Route) -> AnyCoordinatable {
        switch route {
        case .mainTab:
            return MainTabCoordinator().eraseToAnyCoordinatable()
        case .connectToServer:
            return NavigationViewCoordinator(ConnectToServerCoodinator()).eraseToAnyCoordinatable()
        }
    }

    @ViewBuilder
    func start() -> some View {
        SplashView()
    }
}
