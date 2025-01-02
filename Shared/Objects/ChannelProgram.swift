//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

// Note: assumes programs are sorted by start date

/// Structure that has a channel and associated programs.
struct ChannelProgram: Hashable, Identifiable {

    let channel: BaseItemDto
    let programs: [BaseItemDto]

    var currentProgram: BaseItemDto? {
        programs.first { program in
            guard let start = program.startDate,
                  let end = program.endDate else { return false }

            return (start ... end).contains(Date.now)
        }
    }

    func programAfterCurrent(offset: Int) -> BaseItemDto? {
        guard let currentStart = currentProgram?.startDate else { return nil }

        return programs.filter { program in
            guard let start = program.startDate else { return false }
            return start > currentStart
        }[safe: offset]
    }

    var id: String? {
        channel.id
    }
}

extension ChannelProgram: Poster {

    var unwrappedIDHashOrZero: Int {
        channel.id?.hashValue ?? 0
    }

    var displayTitle: String {
        channel.displayTitle
    }

    var systemImage: String {
        channel.systemImage
    }
}
