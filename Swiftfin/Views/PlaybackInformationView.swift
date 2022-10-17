//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI
import VLCUI

struct PlaybackInformationView: View {

    @EnvironmentObject
    private var currentPlaybackInformation: VideoPlayerViewModel.CurrentPlaybackInformation

    var body: some View {
        Form {
            TextPairView(
                leading: "Read Bytes - Input",
                trailing: String(currentPlaybackInformation.playbackInformation?.numberOfReadBytesOnInput ?? 0)
            )
            TextPairView(
                leading: "Read Bytes - Demux",
                trailing: String(currentPlaybackInformation.playbackInformation?.numberOfReadBytesOnDemux ?? 0)
            )
        }
    }
}
