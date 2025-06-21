//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct NavigationInjectionView: View {

    @StateObject
    private var coordinator: NavigationCoordinator
    @EnvironmentObject
    private var rootCoordinator: RootCoordinator

    private let content: AnyView

    init(
        coordinator: NavigationCoordinator,
        @ViewBuilder content: @escaping () -> some View
    ) {
        _coordinator = StateObject(wrappedValue: coordinator)
        self.content = AnyView(content())
    }

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            content
                .navigationDestination(for: NavigationCoordinator.PathItem.self) { pathItem in
                    pathItem.route.destination(in: pathItem.namespace)
                }
        }
        .environment(
            \.router,
            .init(
                navigationCoordinator: coordinator,
                rootCoordinator: rootCoordinator
            )
        )
        .sheet(
            item: $coordinator.presentedSheet
        ) {
            coordinator.presentedSheet = nil
        } content: { route in
            let newCoordinator = NavigationCoordinator()
            let destination = route.destination(in: nil)

            NavigationInjectionView(coordinator: newCoordinator) {
                destination
            }
        }
        .fullScreenCover(
            item: $coordinator.presentedFullScreen
        ) {
            coordinator.presentedFullScreen = nil
        } content: { route in
            let newCoordinator = NavigationCoordinator()
            let destination = route.destination(in: nil)

            NavigationInjectionView(coordinator: newCoordinator) {
                destination
            }
        }
    }
}
