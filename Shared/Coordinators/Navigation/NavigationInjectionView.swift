//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import PreferencesView
import SwiftUI
import Transmission

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
                .navigationDestination(for: NavigationRoute.self) { route in
                    route.destination
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

            NavigationInjectionView(coordinator: newCoordinator) {
                route.destination
            }
        }
        #if os(tvOS)
        .fullScreenCover(
            item: $coordinator.presentedFullScreen
        ) { route in
            let newCoordinator = NavigationCoordinator()

            NavigationInjectionView(coordinator: newCoordinator) {
                route.destination
            }
        }
        #else
        .presentation(
                $coordinator.presentedFullScreen,
                transition: .zoomIfAvailable(
                    options: .init(dimmingVisualEffect: .systemThickMaterialDark),
                    otherwise: .slide(.init(edge: .bottom), options: .init())
                )
            ) { routeBinding, _ in
                let vc = UIPreferencesHostingController {
                    let newCoordinator = NavigationCoordinator()

                    NavigationInjectionView(coordinator: newCoordinator) {
                        routeBinding.wrappedValue.destination
                    }
                }

                // TODO: presentation options for customizing background color, dimming effect, etc.
                vc.view.backgroundColor = .black

                return vc
            }
        #endif
    }
}
