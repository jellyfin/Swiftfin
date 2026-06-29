//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

let guideMinimumBlock: TimeInterval = 15 * 60

struct GuideSegment: Hashable, Identifiable {

    let programs: [BaseItemDto]
    let start: Date
    let end: Date

    var id: String {
        "\(programs.first?.id ?? "")-\(programs.last?.id ?? "")-\(start.timeIntervalSinceReferenceDate)"
    }

    var isGroup: Bool {
        programs.count > 1
    }

    func isCurrent(at date: Date) -> Bool {
        programs.contains { program in
            guard let start = program.startDate, let end = program.endDate else { return false }
            return (start ... end).contains(date)
        }
    }
}

enum GuideRowItem: Hashable, Identifiable {

    case gap(start: Date, end: Date)
    case segment(GuideSegment)

    var id: String {
        switch self {
        case let .gap(start, end):
            "gap-\(start.timeIntervalSinceReferenceDate)-\(end.timeIntervalSinceReferenceDate)"
        case let .segment(segment):
            segment.id
        }
    }

    var start: Date {
        switch self {
        case let .gap(start, _):
            start
        case let .segment(segment):
            segment.start
        }
    }

    var end: Date {
        switch self {
        case let .gap(_, end):
            end
        case let .segment(segment):
            segment.end
        }
    }
}

extension GuideRowItem {

    static func build(
        programs: [BaseItemDto],
        windowStart: Date,
        windowEnd: Date
    ) -> [GuideRowItem] {

        let clamped = programs.compactMap { program -> (BaseItemDto, Date, Date)? in
            guard let start = program.startDate, let end = program.endDate else { return nil }
            let clampedStart = max(start, windowStart)
            let clampedEnd = min(end, windowEnd)
            guard clampedEnd > clampedStart else { return nil }
            return (program, clampedStart, clampedEnd)
        }
        .sorted { $0.1 < $1.1 }

        var items: [GuideRowItem] = []
        var bucket: [BaseItemDto] = []
        var bucketStart = windowStart
        var bucketEnd = windowStart
        var cursor = windowStart

        func flushBucket() {
            guard bucket.isNotEmpty else { return }

            var end = bucketEnd
            if end.timeIntervalSince(bucketStart) < guideMinimumBlock {
                end = min(bucketStart.addingTimeInterval(guideMinimumBlock), windowEnd)
            }

            items.append(.segment(GuideSegment(programs: bucket, start: bucketStart, end: end)))
            cursor = end
            bucket = []
        }

        for (program, clampedStart, clampedEnd) in clamped {
            let duration = clampedEnd.timeIntervalSince(clampedStart)

            if duration >= guideMinimumBlock {
                flushBucket()

                if clampedStart > cursor {
                    items.append(.gap(start: cursor, end: clampedStart))
                    cursor = clampedStart
                }

                items.append(.segment(GuideSegment(programs: [program], start: clampedStart, end: clampedEnd)))
                cursor = clampedEnd
            } else {
                if bucket.isNotEmpty, clampedStart > bucketEnd {
                    flushBucket()
                }

                if bucket.isEmpty {
                    if clampedStart > cursor {
                        items.append(.gap(start: cursor, end: clampedStart))
                        cursor = clampedStart
                    }
                    bucketStart = clampedStart
                }

                bucket.append(program)
                bucketEnd = max(bucketEnd, clampedEnd)

                if bucketEnd.timeIntervalSince(bucketStart) >= guideMinimumBlock {
                    flushBucket()
                }
            }
        }

        flushBucket()

        return items
    }
}
