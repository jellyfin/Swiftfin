//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import SwiftUI

// TODO: rethink implementation
//       - for updating programs in place

/// Structure that has a channel and associated programs.
struct ChannelProgram: Displayable, Hashable, Identifiable {

    let channel: BaseItemDto
    let programs: [BaseItemDto]

    init(channel: BaseItemDto, programs: [BaseItemDto]) {
        self.channel = channel
        self.programs = programs
            .sorted { program1, program2 in
                guard let start1 = program1.startDate,
                      let start2 = program2.startDate else { return false }

                return start1 < start2
            }
    }

    var channelNumber: String? {
        channel.number ?? channel.channelNumber
    }

    var currentProgram: BaseItemDto? {
        programs.first { program in
            guard let start = program.startDate,
                  let end = program.endDate else { return false }

            return (start ... end).contains(Date.now)
        }
    }

    var displayTitle: String {
        channel.displayTitle
    }

    var id: String? {
        channel.id
    }

    func programAfterCurrent(offset: Int) -> BaseItemDto? {
        guard let currentStart = currentProgram?.startDate else { return nil }

        return programs.filter { program in
            guard let start = program.startDate else { return false }
            return start > currentStart
        }[safe: offset]
    }
}
