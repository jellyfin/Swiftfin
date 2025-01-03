//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct NativeVideoPlayerSettingsView: View {

    @Default(.VideoPlayer.resumeOffset)
    private var resumeOffset

    var body: some View {
        Form {

            Section {

                BasicStepper(
                    title: L10n.resumeOffset,
                    value: $resumeOffset,
                    range: 0 ... 30,
                    step: 1
                )
                .valueFormatter {
                    $0.secondLabel
                }
            } footer: {
                Text(L10n.resumeOffsetDescription)
            }
        }
        .navigationTitle(L10n.nativePlayer)
    }
}
