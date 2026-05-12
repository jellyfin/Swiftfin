//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

/// `Note`: Used for experimental settings that may be removed or implemented officially. Keep for future settings.
struct ExperimentalSettingsView: View {

    static let isEnabled = true

    @Default(.Experimental.downloads)
    private var experimentalDownloads

    @ViewBuilder
    var body: some View {
        Form(systemImage: "flask") {
            Section {
                Toggle(L10n.downloads, isOn: $experimentalDownloads)
            } footer: {
                // swiftlint:disable:next hard_coded_display_string
                Text("Enables local downloads for offline browsing. Playback of downloaded files is not yet supported.")
            }
        }
        .navigationTitle(L10n.experimental)
    }
}
