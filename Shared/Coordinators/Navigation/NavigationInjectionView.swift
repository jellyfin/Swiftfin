//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import PreferencesView
import SwiftUI
import Transmission

// TODO: have full screen zoom presentation zoom from/to center
//       - probably need to make mock view with matching ids

struct PresentationControllerShouldDismissPreferenceKey: PreferenceKey {

    static var defaultValue: Bool = true

    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = nextValue()
    }
}

struct NavigationInjectionView: View {

    @StateObject
    private var coordinator: NavigationCoordinator
    @EnvironmentObject
    private var rootCoordinator: RootCoordinator

    @State
    private var isPresentationInteractive: Bool = true

    private let content: AnyView

    init(
        coordinator: @autoclosure @escaping () -> NavigationCoordinator,
        @ViewBuilder content: @escaping () -> some View
    ) {
        _coordinator = StateObject(wrappedValue: coordinator())
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
        #if os(tvOS)
        // TODO: Workaround for sheet presentation issue on tvOS
        // https://developer.apple.com/documentation/tvos-release-notes/tvos-26_1-release-notes
        // Remove this tvOS section when resolved
        .fullScreenCover(
                item: $coordinator.presentedSheet
            ) {
                coordinator.presentedSheet = nil
            } content: { route in
                let newCoordinator = NavigationCoordinator()

                NavigationInjectionView(coordinator: newCoordinator) {
                    route.destination
                }
                .environmentObject(rootCoordinator)
                .background(.regularMaterial)
            }
        #else // <- Start: Use this for both OS when fixed
            .sheet(
                item: $coordinator.presentedSheet
            ) {
                coordinator.presentedSheet = nil
            } content: { route in
                let newCoordinator = NavigationCoordinator()

                NavigationInjectionView(coordinator: newCoordinator) {
                    route.destination
                }
                .environmentObject(rootCoordinator)
            }
        #endif // <- End
        #if os(tvOS)
        .fullScreenCover(
            item: $coordinator.presentedFullScreen
        ) { route in
            let newCoordinator = NavigationCoordinator()

            NavigationInjectionView(coordinator: newCoordinator) {
                route.destination
            }
            .environmentObject(rootCoordinator)
        }
        #else
        .presentation(
                $coordinator.presentedFullScreen,
                transition: .zoomIfAvailable(
                    options: .init(
                        dimmingVisualEffect: .systemThickMaterialDark,
                        options: .init(
                            isInteractive: isPresentationInteractive
                        )
                    ),
                    otherwise: .slide(.init(edge: .bottom), options: .init(isInteractive: isPresentationInteractive))
                )
            ) { routeBinding, _ in
                let vc = UIPreferencesHostingController {
                    NavigationInjectionView(coordinator: .init()) {
                        routeBinding.wrappedValue.destination
                            .onPreferenceChange(PresentationControllerShouldDismissPreferenceKey.self) { newValue in
                                isPresentationInteractive = newValue
                            }
                    }
                    .environmentObject(rootCoordinator)
                }

                // TODO: presentation options for customizing background color, dimming effect, etc.
                vc.view.backgroundColor = .black

                return vc
            }
        #endif
    }
}
