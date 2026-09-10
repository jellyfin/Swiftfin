//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

#if os(macOS)
import AppKit
import SwiftUI

/// How the AppKit scrollers of an enclosing scroll view should behave.
enum MacScrollerStyle {

    /// No scroller at all. For scroll views that offer another way to move
    /// through their content.
    case none

    /// An auto-hiding overlay scroller that floats over the content instead of
    /// reserving a permanent strip beside it.
    case overlay
}

extension View {

    /// Applies `style` to the AppKit scrollers of the enclosing scroll view.
    ///
    /// `scrollIndicators(.hidden)` alone is ignored while the system is set to
    /// always show scroll bars, which leaves every scroll view with a permanent
    /// legacy scroller. Apply this to a scroll view's *content* so that it can
    /// reach the backing `NSScrollView`.
    func macScrollers(_ style: MacScrollerStyle, axes: Axis.Set = [.horizontal, .vertical]) -> some View {
        background(MacScrollerStyleView(style: style, axes: axes))
    }
}

private struct MacScrollerStyleView: NSViewRepresentable {

    let style: MacScrollerStyle
    let axes: Axis.Set

    func makeNSView(context: Context) -> MacScrollerStyleNSView {
        MacScrollerStyleNSView(style: style, axes: axes)
    }

    func updateNSView(_ nsView: MacScrollerStyleNSView, context: Context) {
        nsView.apply()
    }
}

/// A zero sized view that reaches its enclosing `NSScrollView`. Applying on
/// every layout pass is deliberate: SwiftUI restores the scrollers whenever it
/// rebuilds the scroll view.
private final class MacScrollerStyleNSView: NSView {

    private let style: MacScrollerStyle
    private let axes: Axis.Set

    init(style: MacScrollerStyle, axes: Axis.Set) {
        self.style = style
        self.axes = axes
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        apply()
    }

    override func layout() {
        super.layout()
        apply()
    }

    func apply() {
        guard let scrollView = enclosingScrollView else { return }

        switch style {
        case .none:
            if axes.contains(.horizontal), scrollView.hasHorizontalScroller {
                scrollView.hasHorizontalScroller = false
            }

            if axes.contains(.vertical), scrollView.hasVerticalScroller {
                scrollView.hasVerticalScroller = false
            }
        case .overlay:
            if scrollView.scrollerStyle != .overlay {
                scrollView.scrollerStyle = .overlay
            }

            if !scrollView.autohidesScrollers {
                scrollView.autohidesScrollers = true
            }
        }
    }
}
#endif
