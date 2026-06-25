//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// MARK: - Bruno debug overlay — public instrumentation API

//
// These are the ONLY entry points call sites use. They compile to the real DEBUG engine
// (BrunoDebugCore / BrunoDebugOverlayView) or to inert pass-throughs in release, so production
// code carries zero cost and instrumentation lines need no `#if DEBUG` at the call site.

extension View {

    /// Inject the debug HUD above all app content. Wrap the root once per platform; the panels are
    /// individually toggled from Settings and the frame monitor only runs while one is on.
    func brunoDebugOverlay() -> some View {
        #if DEBUG
        return modifier(BrunoDebugOverlayModifier())
        #else
        return self
        #endif
    }

    /// Count this view's `body` re-evaluations — the "redraws as a result of navigation" signal.
    /// Cheap: a single bool check when the nav overlay is off.
    func brunoDebugRedraw(_ name: String) -> some View {
        #if DEBUG
        if BrunoDebugFlags.redrawEnabled {
            BrunoFrameMonitor.shared.bumpRedraw(name)
        }
        #endif
        return self
    }

    /// Track this view's vertical movement (the layout "graphic math" of a nav scroll) and
    /// attribute coincident frame drags to navigation.
    func brunoDebugLayout(_ name: String) -> some View {
        #if DEBUG
        return modifier(BrunoDebugLayoutModifier(name: name))
        #else
        return self
        #endif
    }

    /// Log a discrete nav-input event when `isFocused` becomes true.
    func brunoDebugNavFocus(_ name: String, isFocused: Bool) -> some View {
        #if DEBUG
        return modifier(BrunoDebugNavFocusModifier(name: name, isFocused: isFocused))
        #else
        return self
        #endif
    }
}
