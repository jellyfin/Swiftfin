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
                    CaseIterablePicker(
                        L10n.maximumBitrate,
                        selection: $appMaximumBitrate
                    )

                    if appMaximumBitrate == PlaybackBitrate.auto {
                        CaseIterablePicker(
                            L10n.testSize,
                            selection: $appMaximumBitrateTest
                        )
                    }
                } footer: {
                    if appMaximumBitrate == PlaybackBitrate.auto {
                        Text(L10n.bitrateTestDescription)
                    }
                }
            }
            .navigationTitle(L10n.maximumBitrate)
    }
}
