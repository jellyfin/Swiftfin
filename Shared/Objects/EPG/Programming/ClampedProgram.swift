//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

struct ClampedProgram {

    let program: BaseItemDto
    let start: Date
    let end: Date

    var isShort: Bool {
        end.timeIntervalSince(start) < 15 * 60
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
