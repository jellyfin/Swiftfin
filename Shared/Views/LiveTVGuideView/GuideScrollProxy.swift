//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import UIKit

final class GuideScrollProxy: NSObject, UIScrollViewDelegate {

    private static let interactiveJumpThreshold: CGFloat = 600

    private let scrollViews = NSHashTable<UIScrollView>.weakObjects()

    private var offsetX: CGFloat = 0
    private var didInitialize = false
    private var isSyncing = false

    func register(
        _ scrollView: UIScrollView,
        nowOffset: CGFloat?
    ) {
        if !scrollViews.contains(scrollView) {
            scrollViews.add(scrollView)
            scrollView.delegate = self
        }

        if !didInitialize {
            let viewport = scrollView.bounds.width

            guard viewport > 0 else { return }

            if let nowOffset {
                let maxOffset = max(0, scrollView.contentSize.width - viewport)
                offsetX = min(max(0, nowOffset - viewport / 2), maxOffset)
            } else {
                offsetX = 0
            }

            didInitialize = true
        }

        if abs(scrollView.contentOffset.x - offsetX) > 0.5 {
            isSyncing = true
            scrollView.setContentOffset(CGPoint(x: offsetX, y: 0), animated: false)
            isSyncing = false
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !isSyncing, scrollViews.contains(scrollView) else { return }

        #if os(iOS)
        guard scrollView.isDragging || scrollView.isDecelerating else { return }
        #else
        guard abs(scrollView.contentOffset.x - offsetX) < Self.interactiveJumpThreshold else {
            isSyncing = true
            scrollView.setContentOffset(CGPoint(x: offsetX, y: scrollView.contentOffset.y), animated: false)
            isSyncing = false
            return
        }
        #endif

        offsetX = scrollView.contentOffset.x
        apply(except: scrollView)
    }

    func reset() {
        offsetX = 0
        didInitialize = false
        apply()
    }

    func scrollTo(centering x: CGFloat) {
        guard let reference = scrollViews.allObjects.first else { return }

        offsetX = max(0, x - reference.bounds.width / 2)
        apply()
    }

    private func apply(except source: UIScrollView? = nil) {
        isSyncing = true
        defer { isSyncing = false }

        for scrollView in scrollViews.allObjects where scrollView !== source {
            if abs(scrollView.contentOffset.x - offsetX) > 0.5 {
                scrollView.setContentOffset(CGPoint(x: offsetX, y: scrollView.contentOffset.y), animated: false)
            }
        }
    }
}
