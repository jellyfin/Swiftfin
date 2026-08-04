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
    }
}

@propertyWrapper
struct Router: DynamicProperty {

    @MainActor
    struct Wrapper {
        let router: NavigationCoordinator.Router
        let dismiss: DismissAction

        private let isRootBox: PublishedBox<Bool?> = .init(initialValue: nil)

        var isRootOfPath: Bool {
            if let boxValue = isRootBox.value {
                return boxValue
            }

            guard let router = router.navigationCoordinator else {
                return false
            }

            let value = router.path.isEmpty
            isRootBox.value = value
            return value
        }

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

    private let wrapperBox: PublishedBox<Wrapper?> = .init(initialValue: nil)

    var wrappedValue: Wrapper {
        if let wrapper = wrapperBox.value {
            return wrapper
        }

        let value = Wrapper(
            router: environment.router,
            dismiss: environment.dismiss
        )
        wrapperBox.value = value
        return value
    }
}

extension EnvironmentValues {

    @Entry
    var router: NavigationCoordinator.Router = .init(
        navigationCoordinator: nil
    )
}
