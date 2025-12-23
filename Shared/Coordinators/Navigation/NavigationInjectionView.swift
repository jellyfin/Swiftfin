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

// TODO: have full screen zoom presentation zoom from/to center
//       - probably need to make mock view with matching ids
// TODO: have presentation dismissal be through preference keys
//       - issue with all of the VC/view wrapping

extension EnvironmentValues {

    @Entry
    var presentationControllerShouldDismiss: Binding<Bool> = .constant(true)
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

        // MARK: - Sheet Presentation

        // tvOS 18.0 had a bug where .sheet() used modal presentation instead of full-screen.
        // This was fixed in tvOS 18.1 (tvOS 26.1).
        // Reference: https://developer.apple.com/documentation/tvos-release-notes/tvos-26_1-release-notes
        #if os(tvOS)
        .modifier(TVSheetPresentationModifier(presentedSheet: $coordinator.presentedSheet))
        #else
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
        #endif
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
                            .environment(\.presentationControllerShouldDismiss, $isPresentationInteractive)
                    }
                }

                // TODO: presentation options for customizing background color, dimming effect, etc.
                vc.view.backgroundColor = .black

                return vc
            }
        #endif
    }
}

// MARK: - tvOS Sheet Presentation Modifier

#if os(tvOS)
/// Handles sheet presentation on tvOS with version-aware behavior.
/// - tvOS 18.1+: Uses native .sheet() (bug fixed in tvOS 26.1)
/// - tvOS 17.0-18.0: Uses .fullScreenCover() with material background as workaround
private struct TVSheetPresentationModifier: ViewModifier {

    @Binding
    var presentedSheet: NavigationRoute?

    func body(content: Content) -> some View {
        if #available(tvOS 18.1, *) {
            content
                .sheet(item: $presentedSheet) {
                    presentedSheet = nil
                } content: { route in
                    let newCoordinator = NavigationCoordinator()

                    NavigationInjectionView(coordinator: newCoordinator) {
                        route.destination
                    }
                }
        } else {
            content
                .fullScreenCover(item: $presentedSheet) {
                    presentedSheet = nil
                } content: { route in
                    let newCoordinator = NavigationCoordinator()

                    NavigationInjectionView(coordinator: newCoordinator) {
                        route.destination
                    }
                    .background(.regularMaterial)
                }
        }
    }
}
#endif
