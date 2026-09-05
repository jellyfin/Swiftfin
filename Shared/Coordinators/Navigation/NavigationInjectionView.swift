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
                        .environment(
                            \.router,
                            .init(
                                navigationCoordinator: coordinator,
                                isRootOfPath: false
                            )
                        )
                }
        }
        .trackingFrame(for: .navigationStack)
        .environment(
            \.router,
            .init(
                navigationCoordinator: coordinator,
                isRootOfPath: true
            )
        )
        .environmentObject(coordinator)
        #if os(tvOS)
            .fullScreenCover(
                item: $coordinator.presentedSheet
            ) {
                coordinator.presentedSheet = nil
            } content: { presentedRoute in
                NavigationInjectionView(coordinator: presentedRoute.coordinator) {
                    presentedRoute.route.destination
                }
                .background(.regularMaterial)
            }
            .fullScreenCover(
                item: $coordinator.presentedFullScreen
            ) { presentedRoute in
                NavigationInjectionView(coordinator: presentedRoute.coordinator) {
                    presentedRoute.route.destination
                }
            }
        #else
            .sheet(
                item: $coordinator.presentedSheet
            ) {
                coordinator.presentedSheet = nil
            } content: { presentedRoute in
                NavigationInjectionView(coordinator: presentedRoute.coordinator) {
                    presentedRoute.route.destination
                }
            }
            .presentation(
                $coordinator.presentedFullScreen,
                transition: .zoomIfAvailable(
                    .init(
                        dimmingVisualEffect: .systemThickMaterialDark,
                        prefersScalePresentingView: false
                    ),
                    options: .init(
                        isInteractive: isPresentationInteractive,
                        preferredPresentationSafeAreaInsets: .zero,
                    ),
                    otherwise: .slide(.init(edge: .bottom), options: .init(isInteractive: isPresentationInteractive))
                )
            ) { presentedRouteBinding, _ in
                let vc = UIPreferencesHostingController {
                    NavigationInjectionView(coordinator: presentedRouteBinding.wrappedValue.coordinator) {
                        presentedRouteBinding.wrappedValue.route.destination
                            .onPreferenceChange(PresentationControllerShouldDismissPreferenceKey.self) { newValue in
                                isPresentationInteractive = newValue
                            }
                    }
                }

                vc.view.backgroundColor = .black

                return vc
            }
        #endif
    }
}
