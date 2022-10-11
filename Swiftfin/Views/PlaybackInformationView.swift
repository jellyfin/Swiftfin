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
    private var currentSecondsHandler: CurrentSecondsHandler

    var body: some View {
        Form {
            
            SplitText(leading: "Read Bytes - Input", trailing: String(currentSecondsHandler.playbackInformation?.numberOfReadBytesOnInput ?? 0))
            SplitText(leading: "Read Bytes - Demux", trailing: String(currentSecondsHandler.playbackInformation?.numberOfReadBytesOnDemux ?? 0))
        }
    }
}
