//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import UIKit

final class GuideVerticalScrollSync {

    private let scrollViews = NSHashTable<UIScrollView>.weakObjects()
    private let observations = NSMapTable<UIScrollView, NSKeyValueObservation>(
        keyOptions: .weakMemory,
        valueOptions: .strongMemory
    )

    private var isSyncing = false

    func register(_ scrollView: UIScrollView) {
        guard !scrollViews.contains(scrollView) else { return }

        scrollViews.add(scrollView)

        let observation = scrollView.observe(\.contentOffset) { [weak self] scrollView, _ in
            self?.contentOffsetDidChange(scrollView)
        }

        observations.setObject(observation, forKey: scrollView)
    }

    private func contentOffsetDidChange(_ source: UIScrollView) {
        guard !isSyncing else { return }

        isSyncing = true
        defer { isSyncing = false }

        for scrollView in scrollViews.allObjects where scrollView !== source {
            if abs(scrollView.contentOffset.y - source.contentOffset.y) > 0.5 {
                scrollView.setContentOffset(
                    CGPoint(x: scrollView.contentOffset.x, y: source.contentOffset.y),
                    animated: false
                )
            }
        }
    }
}
