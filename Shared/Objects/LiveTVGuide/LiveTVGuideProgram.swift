//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Algorithms
import Foundation
import JellyfinAPI

struct LiveTVGuideProgram: Identifiable {

    private static let shortThreshold: TimeInterval = 15 * 60
    private static let minWidth: CGFloat = 50

    let programs: [BaseItemDto]
    let start: Date
    let end: Date

    var isGroup: Bool {
        programs.count > 1
    }

    var id: String {
        guard let firstID = programs.first?.id else {
            return "\(start.timeIntervalSince1970)"
        }

        return isGroup ? "group-\(firstID)-\(programs.count)" : firstID
    }

    func isAiring(at date: Date) -> Bool {
        programs.contains { program in
            guard let start = program.startDate, let end = program.endDate else { return false }
            return (start ... end).contains(date)
        }
    }
}

// MARK: - Positioning

extension LiveTVGuideProgram {

    struct Positioned: Identifiable {

        let entry: LiveTVGuideProgram
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
        layout: LiveTVGuideLayout
    ) -> [Positioned] {
        var result: [Positioned] = []
        var runningX: CGFloat = 0

        for entry in entries(from: programs, startDate: startDate, endDate: endDate) {
            let x = max(layout.width(from: startDate, to: entry.start), runningX)
            let endX = layout.width(from: startDate, to: entry.end)
            let width = max(endX - x, Self.minWidth)

            result.append(Positioned(entry: entry, x: x, width: width))
            runningX = x + width
        }

        return result
    }
}

// MARK: - Grouping

private extension LiveTVGuideProgram {

    struct Block {

        let program: BaseItemDto
        let start: Date
        let end: Date

        var isShort: Bool {
            end.timeIntervalSince(start) < LiveTVGuideProgram.shortThreshold
        }

        init?(_ program: BaseItemDto, clampedTo span: ClosedRange<Date>) {
            guard let start = program.startDate, let end = program.endDate else { return nil }

            let clampedStart = max(start, span.lowerBound)
            let clampedEnd = min(end, span.upperBound)

            guard clampedEnd > clampedStart else { return nil }

            self.program = program
            self.start = clampedStart
            self.end = clampedEnd
        }
    }

    static func entries(
        from programs: [BaseItemDto],
        startDate: Date,
        endDate: Date
    ) -> [LiveTVGuideProgram] {
        programs
            .compactMap { Block($0, clampedTo: startDate ... endDate) }
            .sorted(using: \.start)
            .chunked { $0.isShort && $1.isShort }
            .map { blocks in
                LiveTVGuideProgram(
                    programs: blocks.map(\.program),
                    start: blocks.first!.start,
                    end: blocks.last!.end
                )
            }
    }
}
