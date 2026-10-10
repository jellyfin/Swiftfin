//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer.PlaybackControls {

    /// Wall-clock time the current item finishes, as in jellyfin-web.
    /// Hidden for live streams and for recordings still in progress,
    /// whose runtime keeps growing.
    struct EndsAtText: View {

        @EnvironmentObject
        private var manager: MediaPlayerManager
        @EnvironmentObject
        private var scrubbedSecondsBox: PublishedBox<Duration>

        private var endDate: Date? {
            guard !manager.item.isLiveStream,
                  manager.item.type != .recording,
                  let runtime = manager.item.runtime,
                  runtime > .zero,
                  manager.rate > 0
            else { return nil }

            let remaining = max(runtime - scrubbedSecondsBox.value, .zero)
            return Date.now.addingTimeInterval(remaining.seconds / manager.rate)
        }

        var body: some View {
            if let endDate {
                Text(L10n.endsAt(endDate.formatted(date: .omitted, time: .shortened)))
                    .monospacedDigit()
                    .lineLimit(1)
            }
        }
    }
}
