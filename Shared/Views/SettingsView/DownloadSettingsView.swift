//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct DownloadSettingsView: View {

    @Default(.Downloads.isLyricsEnabled)
    private var isLyricsEnabled
    @Default(.Downloads.isSubtitlesEnabled)
    private var isSubtitlesEnabled
    @Default(.Downloads.isTrickplayEnabled)
    private var isTrickplayEnabled

    var body: some View {
        Form(systemImage: "arrow.down.circle") {
            Section(L10n.video) {
                Toggle(L10n.subtitles, isOn: $isSubtitlesEnabled)

                Toggle(L10n.trickplays, isOn: $isTrickplayEnabled)

                // TODO: default bitrate for transcoded downloads
                // CaseIterablePicker(L10n.maximumBitrate, selection: $videoMaxBitrate)
            }

            Section(L10n.audio) {
                // TODO: enable with audio downloads
                Toggle(L10n.lyrics, isOn: $isLyricsEnabled)
                    .disabled(true)

                // TODO: default bitrate for transcoded downloads
                // CaseIterablePicker(L10n.maximumBitrate, selection: $audioMaxBitrate)
            }
        }
        .navigationTitle(L10n.downloads)
    }
}
