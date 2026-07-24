//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import UIKit

final class EPGProxy: ObservableObject {

    private weak var contentScrollView: UIScrollView?

    private var didCenter = false
    private var isSyncingHorizontally = false
    private var isSyncingVertically = false

    private let horizontalObservations = NSMapTable<UIScrollView, NSKeyValueObservation>(
        keyOptions: .weakMemory,
        valueOptions: .strongMemory
    )
    private let verticalObservations = NSMapTable<UIScrollView, NSKeyValueObservation>(
        keyOptions: .weakMemory,
        valueOptions: .strongMemory
    )

    func registerContent(_ scrollView: UIScrollView, centeringOn target: CGFloat?) {
        contentScrollView = scrollView

        registerHorizontal(scrollView)

        if !didCenter, let target, let offset = offset(centering: target) {
            scrollView.setContentOffset(
                CGPoint(x: offset, y: scrollView.contentOffset.y),
                animated: false
            )
            didCenter = true
        }
    }

    func registerHorizontal(_ scrollView: UIScrollView) {
        guard horizontalObservations.object(forKey: scrollView) == nil else { return }

        let observation = scrollView.observe(\.contentOffset) { [weak self] scrollView, _ in
            self?.horizontalOffsetDidChange(scrollView)
        }

        horizontalObservations.setObject(observation, forKey: scrollView)
    }

    func registerVertical(_ scrollView: UIScrollView) {
        guard verticalObservations.object(forKey: scrollView) == nil else { return }

        let observation = scrollView.observe(\.contentOffset) { [weak self] scrollView, _ in
            self?.verticalOffsetDidChange(scrollView)
        }

        verticalObservations.setObject(observation, forKey: scrollView)
    }

    func reset() {
        guard let contentScrollView else { return }

        didCenter = false
        contentScrollView.setContentOffset(
            CGPoint(x: 0, y: contentScrollView.contentOffset.y),
            animated: false
        )
    }

    func scrollTo(centering target: CGFloat) {
        guard let contentScrollView, let offset = offset(centering: target) else { return }

        contentScrollView.setContentOffset(
            CGPoint(x: offset, y: contentScrollView.contentOffset.y),
            animated: true
        )
    }

    private func offset(centering target: CGFloat) -> CGFloat? {
        guard let contentScrollView else { return nil }

        let viewport = contentScrollView.bounds.width

        guard viewport > 0, contentScrollView.contentSize.width > viewport else { return nil }

        return clamp(
            target - viewport / 2,
            min: 0,
            max: contentScrollView.contentSize.width - viewport
        )
    }

    private func horizontalOffsetDidChange(_ source: UIScrollView) {
        guard !isSyncingHorizontally else { return }

        isSyncingHorizontally = true
        defer { isSyncingHorizontally = false }

        let scrollViews = horizontalObservations.keyEnumerator().allObjects as? [UIScrollView] ?? []

        for scrollView in scrollViews {
            guard scrollView !== source,
                  abs(scrollView.contentOffset.x - source.contentOffset.x) > 0.5
            else { continue }

            scrollView.setContentOffset(
                CGPoint(x: source.contentOffset.x, y: scrollView.contentOffset.y),
                animated: false
            )
        }
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
