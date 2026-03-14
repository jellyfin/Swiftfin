//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension NavigationCoordinator {

    @MainActor
    struct Router {

        let navigationCoordinator: NavigationCoordinator?
        let rootCoordinator: RootCoordinator?

        func route(
            to route: NavigationRoute,
            transition: NavigationRoute.TransitionType? = nil,
            in namespace: Namespace.ID? = nil
        ) {
            var route = route
            route.namespace = namespace
            route.transitionType = transition ?? route.transitionType
            navigationCoordinator?.push(route)
        }

        func root(
            _ root: RootItem
        ) {
            rootCoordinator?.root(root)
        }
    }
}

@propertyWrapper
struct Router: DynamicProperty {

    @MainActor
    struct Wrapper {
        let router: NavigationCoordinator.Router
        let dismiss: DismissAction

        func route(
            to route: NavigationRoute,
            in namespace: Namespace.ID? = nil
        ) {
            router.route(
                to: route,
                transition: nil,
                in: namespace
            )
        }

        func route(
            to route: NavigationRoute,
            style: NavigationRoute.TransitionStyle,
            in namespace: Namespace.ID? = nil
        ) {
            router.route(
                to: route,
                transition: .automatic(style),
                in: namespace
            )
        }

        func route(
            to route: NavigationRoute,
            withNamespace: @escaping (Namespace.ID) -> NavigationRoute.TransitionStyle,
            in namespace: Namespace.ID? = nil
        ) {
            router.route(
                to: route,
                transition: .withNamespace(withNamespace),
                in: namespace
            )
        }
    }

    // `.dismiss` causes changes on disappear
    @Environment(\.self)
    private var environment

    var wrappedValue: Wrapper {
        .init(
            router: environment.router,
            dismiss: environment.dismiss
        )
    }
}

extension EnvironmentValues {

    @Entry
    var router: NavigationCoordinator.Router = .init(
        navigationCoordinator: nil,
        rootCoordinator: nil
    )
}
