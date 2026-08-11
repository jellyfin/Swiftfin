//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

@MainActor
final class NavigationCoordinator: ObservableObject {

    @Published
    var path: [NavigationRoute] = []

    @Published
    var presentedSheet: NavigationRoute?
    @Published
    var presentedFullScreen: NavigationRoute?

    func push(
        _ route: NavigationRoute
    ) {
        let style = route.transitionStyle

        switch style {
        case .push:
            path.append(route)
        case .sheet:
            presentedSheet = route
        case .fullscreen:
            withAnimation {
                presentedFullScreen = route
            }
        }
    }
}
