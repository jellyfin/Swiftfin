//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

@MainActor
final class NavigationCoordinator: ObservableObject {

    @Published
    var path: [NavigationRoute] = []

    @Published
    var presentedSheet: NavigationRoute?
    @Published
    var presentedFullScreen: NavigationRoute?

    /// Depth of this coordinator within a nested presentation chain (0 == a tab root). Set by
    /// `NavigationInjectionView` when it creates the child coordinator for a presented route.
    var depth: Int = 0

    /// The outermost coordinator of this chain (a tab root). `nil` means this coordinator *is*
    /// the root. Weak so the chain doesn't retain upward.
    weak var parentRootCoordinator: NavigationCoordinator?

    /// The outermost coordinator — `self` when this is already a tab root.
    var rootCoordinator: NavigationCoordinator {
        parentRootCoordinator ?? self
    }

    func push(
        _ route: NavigationRoute
    ) {
        let style = route.transitionStyle

        // `.push` is hierarchical drill-down → it belongs on the `NavigationStack` path on *every*
        // platform (Apple's recommended pattern). On tvOS the deep item chain is therefore pure
        // push (no nested covers), which both fixes the deep-navigation memory/stutter problem and
        // sidesteps the tvOS modal-presentation bug — that bug only affects sheets/full-screen
        // covers, which keep using the cover workaround below.
        //
        // No depth cap: the stack only renders the *top* page and frees popped pages, so deep
        // drilling stays lightweight. (We tried trimming the oldest entry to bound depth, but
        // removing the bottom of a *live* `NavigationStack` forces tvOS to rebuild the stack —
        // it yanks focus and visibly flickers back a page. Letting the user drill indefinitely is
        // both what's wanted and the only glitch-free option; `.critical` memory pressure is the
        // backstop, see `SwiftfinApp+configure`.)
        switch style {
        case .push:
            path.append(route)
        case .sheet:
            presentedSheet = route
        case .fullscreen:
            #if os(tvOS)
            presentedFullScreen = route
            #else
            withAnimation {
                presentedFullScreen = route
            }
            #endif
        }
    }

    /// Collapses the entire navigation chain back to the tab root (e.g. Home), in one step:
    /// pops every pushed page off the stack and dismisses any presented cover stacked on it.
    func dismissToRoot() {
        let root = rootCoordinator
        root.path.removeAll()
        root.presentedSheet = nil
        root.presentedFullScreen = nil
    }
}
