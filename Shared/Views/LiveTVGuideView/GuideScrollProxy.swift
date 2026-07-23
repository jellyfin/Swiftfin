//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import UIKit

final class GuideScrollProxy: ObservableObject {

    private final class Observations {

        let contentOffset: NSKeyValueObservation
        let contentSize: NSKeyValueObservation

        init(contentOffset: NSKeyValueObservation, contentSize: NSKeyValueObservation) {
            self.contentOffset = contentOffset
            self.contentSize = contentSize
        }
    }

    private static let interactiveJumpThreshold: CGFloat = 600
    private static let windowQuantum: CGFloat = 300
    private static let windowMargin: CGFloat = 600

    @Published
    private(set) var visibleWindow: ClosedRange<CGFloat> = 0 ... CGFloat.greatestFiniteMagnitude

    private let scrollViews = NSHashTable<UIScrollView>.weakObjects()
    private let observations = NSMapTable<UIScrollView, Observations>(
        keyOptions: .weakMemory,
        valueOptions: .strongMemory
    )

    private var offsetX: CGFloat = 0
    private var didInitialize = false
    private var isSyncing = false

    func register(
        _ scrollView: UIScrollView,
        nowOffset: CGFloat?
    ) {
        if !scrollViews.contains(scrollView) {
            scrollViews.add(scrollView)

            let contentOffset = scrollView.observe(\.contentOffset) { [weak self] scrollView, _ in
                self?.contentOffsetDidChange(scrollView)
            }

            let contentSize = scrollView.observe(\.contentSize) { [weak self] scrollView, _ in
                self?.apply(to: scrollView)
            }

            observations.setObject(
                Observations(contentOffset: contentOffset, contentSize: contentSize),
                forKey: scrollView
            )
        }

        if !didInitialize {
            let viewport = scrollView.bounds.width

            if viewport > 0, scrollView.contentSize.width > viewport {
                if let nowOffset {
                    let maxOffset = max(0, scrollView.contentSize.width - viewport)
                    offsetX = min(max(0, nowOffset - viewport / 2), maxOffset)
                } else {
                    offsetX = 0
                }

                didInitialize = true
                updateVisibleWindow()
            }
        }

        apply(to: scrollView)

        DispatchQueue.main.async { [weak self, weak scrollView] in
            guard let self, let scrollView else { return }
            self.apply(to: scrollView)
        }
    }

    func reset() {
        offsetX = 0
        didInitialize = false
        apply()
        updateVisibleWindow()
    }

    func scrollTo(centering x: CGFloat) {
        guard let reference = scrollViews.allObjects.first else { return }

        offsetX = max(0, x - reference.bounds.width / 2)
        apply()
        updateVisibleWindow()
    }

    private func contentOffsetDidChange(_ scrollView: UIScrollView) {
        guard !isSyncing, scrollViews.contains(scrollView) else { return }

        #if os(iOS)
        guard scrollView.isTracking || scrollView.isDragging || scrollView.isDecelerating else {
            snap(scrollView)
            return
        }
        #else
        guard abs(scrollView.contentOffset.x - offsetX) < Self.interactiveJumpThreshold else {
            snap(scrollView)
            return
        }
        #endif

        guard abs(scrollView.contentOffset.x - offsetX) > 0.5 else { return }

        offsetX = scrollView.contentOffset.x
        apply(except: scrollView)
    }

    private func snap(_ scrollView: UIScrollView) {
        guard abs(scrollView.contentOffset.x - offsetX) > 0.5 else { return }

        isSyncing = true
        scrollView.setContentOffset(CGPoint(x: offsetX, y: scrollView.contentOffset.y), animated: false)
        isSyncing = false
    }

    private func apply(to scrollView: UIScrollView) {
        guard !scrollView.isTracking, !scrollView.isDragging, !scrollView.isDecelerating else { return }

        snap(scrollView)
    }

    private func apply(except source: UIScrollView? = nil) {
        for scrollView in scrollViews.allObjects where scrollView !== source {
            snap(scrollView)
        }
    }
}
