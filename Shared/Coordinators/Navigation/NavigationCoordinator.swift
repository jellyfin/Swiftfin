//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

@MainActor
final class NavigationCoordinator: ObservableObject {

    struct PathItem: Hashable {
        let route: NavigationRoute
        let namespace: Namespace.ID?
    }

    @Published
    var path: [PathItem] = []

    @Published
    var presentedSheet: NavigationRoute?
    @Published
    var presentedFullScreen: NavigationRoute?

    func push(
        _ route: NavigationRoute,
        style: NavigationRoute.TransitionStyle? = nil,
        in namespace: Namespace.ID? = nil
    ) {
        let style = style ?? route.transitionStyle

        #if os(tvOS)
        switch style {
        case .push, .sheet:
            presentedSheet = route
        case .fullscreen:
            presentedFullScreen = route
        }
        #else
        switch style {
        case .push:
            path.append(
                PathItem(
                    route: route,
                    namespace: namespace
                )
            )
        case .sheet:
            presentedSheet = route
        case .fullscreen:
            presentedFullScreen = route
        }
        #endif
    }
}
