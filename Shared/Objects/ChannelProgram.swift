//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

// Note: assumes programs are sorted by start date

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

    var nextProgram: BaseItemDto? {
        guard let currentStart = currentProgram?.startDate else { return nil }

        return programs.first { program in
            guard let start = program.startDate else { return false }
            return start > currentStart
        }
    }

    var id: String? {
        channel.id
    }
}

extension ChannelProgram: Poster {

    var displayTitle: String {
        channel.displayTitle
    }

    var subtitle: String? {
        nil
    }

    var typeSystemImage: String? {
        "tv"
    }

    func portraitPosterImageSource(maxWidth: CGFloat) -> ImageSource {
        channel.imageSource(.primary, maxWidth: maxWidth)
    }
}
