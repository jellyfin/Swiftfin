//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct MaximumBitrateSettingsView: View {
    @Default(.VideoPlayer.appMaximumBitrate)
    private var appMaximumBitrate
    @Default(.VideoPlayer.appMaximumBitrateTest)
    private var appMaximumBitrateTest

    var body: some View {
        SplitFormWindowView()
            .descriptionView {
                Image(systemName: "network")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 400)
            }
            .contentView {

                Section {

                    InlineEnumToggle(title: L10n.maximumBitrate, selection: $appMaximumBitrate)

                    if appMaximumBitrate == PlaybackBitrate.auto {
                        InlineEnumToggle(title: L10n.testSize, selection: $appMaximumBitrateTest)
                    }
                } header: {
                    L10n.playbackQuality.text
                } footer: {
                    if appMaximumBitrate == PlaybackBitrate.auto {
                        L10n.bitrateTestDescription.text
                    }
                }
            }
            .navigationTitle(L10n.maximumBitrate)
    }
}
