//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension NavigationCoordinator {

    @MainActor
    struct Router {

        let navigationCoordinator: NavigationCoordinator?
        let rootCoordinator: RootCoordinator?

        func route(
            to route: NavigationRoute,
            in namespace: Namespace.ID? = nil
        ) {
            navigationCoordinator?.push(route, in: namespace)
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
    struct RouterWrapper {
        let router: NavigationCoordinator.Router
        let dismiss: DismissAction

        func route(
            to route: NavigationRoute,
            in namespace: Namespace.ID? = nil
        ) {
            router.route(to: route, in: namespace)
        }
    }

    @Environment(\.dismiss)
    private var dismiss
    @Environment(\.router)
    private var router

    var wrappedValue: RouterWrapper {
        .init(router: router, dismiss: dismiss)
    }
}

extension EnvironmentValues {

    @Entry
    var router: NavigationCoordinator.Router = .init(
        navigationCoordinator: nil,
        rootCoordinator: nil
    )
}
