//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import UIKit

final class GuideScrollProxy: ObservableObject {

    private static let windowQuantum: CGFloat = 300
    private static let windowMargin: CGFloat = 600

    @Published
    private(set) var visibleWindow: ClosedRange<CGFloat> = 0 ... CGFloat.greatestFiniteMagnitude

    private weak var scrollView: UIScrollView?
    private var observation: NSKeyValueObservation?
    private var didInitialize = false

    func register(
        _ scrollView: UIScrollView,
        nowOffset: CGFloat?
    ) {
        if self.scrollView !== scrollView {
            self.scrollView = scrollView

            observation = scrollView.observe(\.contentOffset) { [weak self] _, _ in
                self?.updateVisibleWindow()
            }
        }

        if !didInitialize {
            let viewport = scrollView.bounds.width

            if viewport > 0, scrollView.contentSize.width > viewport {
                if let nowOffset {
                    let maxOffset = max(0, scrollView.contentSize.width - viewport)
                    let x = min(max(0, nowOffset - viewport / 2), maxOffset)

                    scrollView.setContentOffset(CGPoint(x: x, y: 0), animated: false)
                }

                didInitialize = true
            }
        }

        updateVisibleWindow()
    }

    func reset() {
        didInitialize = false
        scrollView?.setContentOffset(.zero, animated: false)
    }

    func scrollTo(centering x: CGFloat) {
        guard let scrollView else { return }

        let viewport = scrollView.bounds.width
        let maxOffset = max(0, scrollView.contentSize.width - viewport)
        let target = min(max(0, x - viewport / 2), maxOffset)

        scrollView.setContentOffset(
            CGPoint(x: target, y: scrollView.contentOffset.y),
            animated: true
        )
    }

    private func updateVisibleWindow() {
        guard let scrollView, scrollView.bounds.width > 0 else { return }

        let quantized = (scrollView.contentOffset.x / Self.windowQuantum).rounded(.down) * Self.windowQuantum
        let window = (quantized - Self.windowMargin) ... (quantized + scrollView.bounds.width + Self.windowQuantum + Self.windowMargin)

        if window != visibleWindow {
            visibleWindow = window
        }
    }
}
