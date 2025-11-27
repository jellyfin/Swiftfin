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
    struct MediaSegmentSection: View {

        @Default(.VideoPlayer.enableMediaSegments)
        private var enableMediaSegments

        var body: some View {
            Section {

                Toggle(L10n.enableMediaSegments, isOn: $enableMediaSegments)

                if enableMediaSegments {
                    NavigationLink(L10n.configureMediaSegments) {
                        MediaSegmentSettingsView()
                    }
                }
            } header: {
                Text(L10n.mediaSegments)
            }
        }
    }
}
