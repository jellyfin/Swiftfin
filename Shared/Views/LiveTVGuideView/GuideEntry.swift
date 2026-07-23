//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

enum GuideEntry: Identifiable {

    private static let shortThreshold: TimeInterval = 15 * 60
    private static let minEntryWidth: CGFloat = 50

    case single(BaseItemDto, start: Date, end: Date)
    case group([BaseItemDto], start: Date, end: Date)

    var start: Date {
        switch self {
        case let .single(_, start, _):
            start
        case let .group(_, start, _):
            start
        }
    }

    var end: Date {
        switch self {
        case let .single(_, _, end):
            end
        case let .group(_, _, end):
            end
        }
    }

    var id: String {
        switch self {
        case let .single(program, start, _):
            program.id ?? "\(start.timeIntervalSince1970)"
        case let .group(programs, start, _):
            "group-\(programs.first?.id ?? "\(start.timeIntervalSince1970)")-\(programs.count)"
        }
    }

    static func entries(
        from programs: [BaseItemDto],
        startDate: Date,
        endDate: Date,
        shortThreshold: TimeInterval
    ) -> [GuideEntry] {
        struct Block {
            let program: BaseItemDto
            let start: Date
            let end: Date
            let isShort: Bool
        }

        let blocks: [Block] = programs.compactMap { program in
            guard let start = program.startDate, let end = program.endDate else { return nil }
            let clampedStart = max(start, startDate)
            let clampedEnd = min(end, endDate)
            guard clampedEnd > clampedStart else { return nil }
            return Block(
                program: program,
                start: clampedStart,
                end: clampedEnd,
                isShort: clampedEnd.timeIntervalSince(clampedStart) < shortThreshold
            )
        }
        .sorted { $0.start < $1.start }

        var result: [GuideEntry] = []
        var pending: [Block] = []

        func flush() {
            if pending.count >= 2, let first = pending.first, let last = pending.last {
                result.append(.group(pending.map(\.program), start: first.start, end: last.end))
            } else if let only = pending.first {
                result.append(.single(only.program, start: only.start, end: only.end))
            }
            pending.removeAll()
        }

        for block in blocks {
            if block.isShort {
                pending.append(block)
            } else {
                flush()
                result.append(.single(block.program, start: block.start, end: block.end))
            }
        }
        flush()

        return result
    }
}

extension GuideEntry {

    struct Positioned: Identifiable {

        let entry: GuideEntry
        let x: CGFloat
        let width: CGFloat

        var id: String {
            entry.id
        }
    }

    static func positioned(
        from programs: [BaseItemDto],
        startDate: Date,
        endDate: Date,
        pointsPerMinute: CGFloat
    ) -> [Positioned] {
        let entries = entries(
            from: programs,
            startDate: startDate,
            endDate: endDate,
            shortThreshold: shortThreshold
        )

        var result: [Positioned] = []
        var runningX: CGFloat = 0

        func width(from start: Date, to end: Date) -> CGFloat {
            max(0, CGFloat(start.distance(to: end) / 60) * pointsPerMinute)
        }

        for entry in entries {
            let x = max(width(from: startDate, to: entry.start), runningX)
            let endX = width(from: startDate, to: entry.end)
            let entryWidth = max(endX - x, Self.minEntryWidth)

            result.append(Positioned(entry: entry, x: x, width: entryWidth))
            runningX = x + entryWidth
        }

        return result
    }
}
