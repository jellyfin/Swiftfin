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
                isShort: end.timeIntervalSince(start) < shortThreshold
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
