//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import IdentifiedCollections
import JellyfinAPI
import Observation

@MainActor
@Observable
final class VideoPlayerOverlayActionStore {

    let segmentHistory: SegmentHistory
    private(set) var actions: IdentifiedArrayOf<VideoPlayerOverlayAction> = []

    init(itemID: String? = nil, resuming history: SegmentHistory? = nil) {
        if let itemID, let history, history.itemID == itemID {
            self.segmentHistory = history
        } else {
            self.segmentHistory = SegmentHistory(itemID: itemID)
        }
    }

    func publish(_ action: VideoPlayerOverlayAction) {
        actions.updateOrAppend(action)
    }

    @discardableResult
    func withdraw(_ id: UUID) -> VideoPlayerOverlayAction? {
        actions.remove(id: id)
    }

    func dismiss(_ id: UUID) {
        withdraw(id)?.onDismiss()
    }
}

extension VideoPlayerOverlayActionStore {

    @MainActor
    final class SegmentHistory {

        fileprivate let itemID: String?
        private var boundaries: [Duration]?
        private var currentBoundary: Duration?
        private var remaining: [MediaSegment] = []
        private var pending: [MediaSegment] = []

        var isLoaded: Bool {
            boundaries != nil
        }

        fileprivate init(itemID: String?) {
            self.itemID = itemID
        }

        func load(_ values: [MediaSegmentDto]) {
            guard let itemID, !isLoaded else { return }

            remaining = MediaSegment.segments(from: values, itemID: itemID)
            boundaries = remaining.flatMap { [$0.start, $0.end] }.sorted()
        }

        func pendingSegment(
            at position: Duration,
            duration: Duration?,
            for configuration: MediaSegmentConfiguration
        ) -> MediaSegment? {
            guard let boundaries else { return nil }

            let boundary = duration.map { position >= $0 } == true
                ? nil : boundaries.split(after: position, sortedBy: { $0 }).atOrBefore.last
            if boundary != currentBoundary {
                let previous = currentBoundary
                currentBoundary = boundary
                guard let boundary else {
                    pending = []
                    return nil
                }

                pending = remaining.filter { segment in
                    let range = segment.start ..< segment.end
                    guard range.contains(boundary) else { return false }

                    // Crossing an overlapping boundary continues the same visit.
                    if let previous, range.contains(previous) {
                        return pending.contains(segment)
                    }
                    return true
                }
            }

            return pending.first { configuration[$0.type] != .off }
        }

        func consume(_ segment: MediaSegment, repeatMode: MediaSegmentRepeatMode) {
            pending.removeAll { $0 == segment }

            if repeatMode == .once {
                remaining.removeAll { $0 == segment }
            }
        }
    }
}
