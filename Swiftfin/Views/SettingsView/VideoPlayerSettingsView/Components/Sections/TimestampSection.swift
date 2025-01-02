//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension VideoPlayerSettingsView {
    struct TimestampSection: View {

        @Default(.VideoPlayer.Overlay.trailingTimestampType)
        private var trailingTimestampType
        @Default(.VideoPlayer.Overlay.showCurrentTimeWhileScrubbing)
        private var showCurrentTimeWhileScrubbing
        @Default(.VideoPlayer.Overlay.timestampType)
        private var timestampType

        var body: some View {
            Section(L10n.timestamp) {

                Toggle(L10n.scrubCurrentTime, isOn: $showCurrentTimeWhileScrubbing)

                CaseIterablePicker(L10n.timestampType, selection: $timestampType)

                CaseIterablePicker(L10n.trailingValue, selection: $trailingTimestampType)
            }
        }
    }
}
