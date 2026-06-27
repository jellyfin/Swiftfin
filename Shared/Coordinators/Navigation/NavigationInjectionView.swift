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
import UIKit

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

    // Creates a child coordinator for a presented sheet/full-screen chain, carrying over the depth
    // and tab-root pointer. Kept as a method (not inline) so the mutating setup isn't a bare
    // statement inside a `@ViewBuilder` closure (which only allows declarations + view expressions).
    private func makeChildCoordinator() -> NavigationCoordinator {
        let newCoordinator = NavigationCoordinator()
        newCoordinator.depth = coordinator.depth + 1
        newCoordinator.parentRootCoordinator = coordinator.rootCoordinator
        return newCoordinator
    }

    // Whenever there's somewhere to collapse back to — either a pushed drill-down chain on this
    // coordinator's path, or a presented cover chain (depth > 0) — a long-press of the Menu/Back
    // button jumps straight to the tab root (Home). A normal short Menu press is unaffected and
    // still pops one level. At a truly empty tab root there's nothing to collapse, so the catcher
    // isn't attached and the system's default Menu behavior is preserved.
    @ViewBuilder
    private var menuLongPressCatcher: some View {
        #if os(tvOS)
        if coordinator.depth > 0 || coordinator.path.isNotEmpty {
            MenuLongPressCatcher {
                coordinator.dismissToRoot()
            }
        }
        #endif
    }

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            content
                .navigationDestination(for: NavigationRoute.self) { route in
                    route.destination
                }
        }
        .background {
            menuLongPressCatcher
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
                // Track chain depth + the outermost (tab-root) coordinator so deep chains can be
                // capped and a long-press of Menu can collapse straight back to the tab root.
                let newCoordinator = makeChildCoordinator()

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
            let newCoordinator = makeChildCoordinator()

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

#if os(tvOS)

/// Adds a **long-press** handler for the Siri Remote Menu/Back button to the key window. A long
/// press fires `action` (used to collapse the navigation chain and jump Home); a normal short Menu
/// press is left untouched, so it still pops one level. This only ever *adds* a recognizer — if it
/// doesn't fire for any reason, the Back button still behaves normally (safe failure mode).
private struct MenuLongPressCatcher: UIViewRepresentable {

    let action: () -> Void

    func makeUIView(context: Context) -> UIView {
        let view = CatcherView()
        view.onLongMenu = action
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        (uiView as? CatcherView)?.onLongMenu = action
    }

    final class CatcherView: UIView {

        var onLongMenu: (() -> Void)?

        private weak var attachedWindow: UIWindow?
        private var recognizer: UILongPressGestureRecognizer?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard recognizer == nil, let window else { return }

            let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongMenu(_:)))
            recognizer.allowedPressTypes = [NSNumber(value: UIPress.PressType.menu.rawValue)]
            recognizer.minimumPressDuration = 0.45
            window.addGestureRecognizer(recognizer)

            self.recognizer = recognizer
            attachedWindow = window
        }

        override func willMove(toWindow newWindow: UIWindow?) {
            super.willMove(toWindow: newWindow)
            guard newWindow == nil, let recognizer else { return }
            attachedWindow?.removeGestureRecognizer(recognizer)
            self.recognizer = nil
            attachedWindow = nil
        }

        @objc
        private func handleLongMenu(_ recognizer: UILongPressGestureRecognizer) {
            if recognizer.state == .began {
                onLongMenu?()
            }
        }
    }
}

#endif
