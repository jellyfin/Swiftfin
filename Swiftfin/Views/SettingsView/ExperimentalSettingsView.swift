//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct ExperimentalSettingsView: View {

    @Default(.Experimental.forceDirectPlay)
    private var forceDirectPlay
    @Default(.Experimental.syncSubtitleStateWithAdjacent)
    private var syncSubtitleStateWithAdjacent
    @Default(.Experimental.liveTVAlphaEnabled)
    private var liveTVAlphaEnabled
    @Default(.Experimental.liveTVForceDirectPlay)
    private var liveTVForceDirectPlay

    var body: some View {
        Form {
            Section {

                Toggle("Force Direct Play", isOn: $forceDirectPlay)

//                Toggle("Sync Subtitles with Adjacent Episodes", isOn: $syncSubtitleStateWithAdjacent)
            }

            Section {

                Toggle("Live TV (Alpha)", isOn: $liveTVAlphaEnabled)

                Toggle("Live TV Force Direct Play", isOn: $liveTVForceDirectPlay)

            } header: {
                Text("Live TV")
            }
        }
        .navigationTitle(L10n.experimental)
    }
}
