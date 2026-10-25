//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

struct MediaSegment: Identifiable, Hashable, Sendable {

    let id: String
    let type: MediaSegmentType
    let start: Duration
    let end: Duration

    init?(_ segment: MediaSegmentDto, itemID: String) {
        guard segment.itemID == nil || segment.itemID == itemID,
              let type = segment.type, type != .unknown,
              let start = segment.startTicks, let end = segment.endTicks,
              start >= 0, end > start else { return nil }

        self.id = segment.id ?? "\(type.rawValue):\(start):\(end)"
        self.type = type
        self.start = .ticks(start)
        self.end = .ticks(end)

        guard self.end > self.start else { return nil }
    }

    func skipTarget(at position: Duration, duration: Duration?) -> Duration? {
        guard type == .intro || type == .outro else { return nil }

        let target = duration.map { min(end, $0) } ?? end
        guard position >= start, position < target else { return nil }

        return target
    }

    static func segments(from values: [MediaSegmentDto], itemID: String) -> [MediaSegment] {
        var ids: Set<String> = []

        return values.compactMap { MediaSegment($0, itemID: itemID) }
            .sorted {
                if $0.start != $1.start {
                    return $0.start < $1.start
                }

                if $0.end != $1.end {
                    return $0.end < $1.end
                }

                return $0.id < $1.id
            }
            .filter { ids.insert($0.id).inserted }
    }
}
