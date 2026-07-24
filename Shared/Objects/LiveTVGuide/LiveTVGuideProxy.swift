//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import UIKit

final class LiveTVGuideProxy: ObservableObject {

    private static let windowQuantum: CGFloat = 300
    private static let windowMargin: CGFloat = UIDevice.isTV ? 600 : 300

    @Published
    private(set) var visibleWindow: ClosedRange<CGFloat> = 0 ... .greatestFiniteMagnitude

    private weak var horizontalScrollView: UIScrollView?

    private var horizontalObservation: NSKeyValueObservation?
    private var didCenter = false

    private let verticalObservations = NSMapTable<UIScrollView, NSKeyValueObservation>(
        keyOptions: .weakMemory,
        valueOptions: .strongMemory
    )
    private var isSyncingVertically = false

    // MARK: horizontal

    func register(_ scrollView: UIScrollView, centeringOn x: CGFloat?) {
        if horizontalScrollView !== scrollView {
            horizontalScrollView = scrollView

            horizontalObservation = scrollView.observe(\.contentOffset) { [weak self] _, _ in
                self?.updateVisibleWindow()
            }
        }

        if !didCenter, let x, let offset = offset(centering: x) {
            scrollView.setContentOffset(CGPoint(x: offset, y: 0), animated: false)
            didCenter = true
        }

        updateVisibleWindow()
    }

    func reset() {
        didCenter = false
        horizontalScrollView?.setContentOffset(.zero, animated: false)
    }

    func scrollTo(centering x: CGFloat) {
        guard let horizontalScrollView, let offset = offset(centering: x) else { return }

        horizontalScrollView.setContentOffset(
            CGPoint(x: offset, y: horizontalScrollView.contentOffset.y),
            animated: true
        )
    }

    private func offset(centering x: CGFloat) -> CGFloat? {
        guard let horizontalScrollView else { return nil }

        let viewport = horizontalScrollView.bounds.width

        guard viewport > 0, horizontalScrollView.contentSize.width > viewport else { return nil }

        return clamp(
            x - viewport / 2,
            min: 0,
            max: horizontalScrollView.contentSize.width - viewport
        )
    }

    private func updateVisibleWindow() {
        guard let horizontalScrollView, horizontalScrollView.bounds.width > 0 else { return }

        let quantized = (horizontalScrollView.contentOffset.x / Self.windowQuantum).rounded(.down) * Self.windowQuantum
        let lower = quantized - Self.windowMargin
        let upper = quantized + horizontalScrollView.bounds.width + Self.windowQuantum + Self.windowMargin

        guard lower ... upper != visibleWindow else { return }

        visibleWindow = lower ... upper
    }

    // MARK: vertical

    func registerVertical(_ scrollView: UIScrollView) {
        guard verticalObservations.object(forKey: scrollView) == nil else { return }

        let observation = scrollView.observe(\.contentOffset) { [weak self] scrollView, _ in
            self?.verticalOffsetDidChange(scrollView)
        }

        verticalObservations.setObject(observation, forKey: scrollView)
    }

    private func verticalOffsetDidChange(_ source: UIScrollView) {
        guard !isSyncingVertically else { return }

        isSyncingVertically = true
        defer { isSyncingVertically = false }

        let scrollViews = verticalObservations.keyEnumerator().allObjects as? [UIScrollView] ?? []

        for scrollView in scrollViews {
            guard scrollView !== source,
                  abs(scrollView.contentOffset.y - source.contentOffset.y) > 0.5
            else { continue }

            scrollView.setContentOffset(
                CGPoint(x: scrollView.contentOffset.x, y: source.contentOffset.y),
                animated: false
            )
        }
    }
}
