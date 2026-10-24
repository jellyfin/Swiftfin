//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

struct SubtitleTrackSelection: Equatable {

    var primary: Int
    var secondary: Int
}

struct SubtitleCue: Hashable {

    let text: String
    var track: Int = -1
    var secondary = false
}

struct SkipBackSubtitles {

    let end: Duration
    private var finishingCues: Set<SubtitleCue>?

    init(from origin: Duration, to landing: Duration) {
        end = landing + (origin - landing).clamped(to: .seconds(10) ... .seconds(30))
    }

    mutating func hasFinished(at position: Duration, cues: Set<SubtitleCue>) -> Bool {
        guard position >= end else { return false }

        if let finishingCues {
            self.finishingCues = finishingCues.intersection(cues)
        } else {
            finishingCues = cues
        }

        return finishingCues?.isEmpty == true
    }
}
