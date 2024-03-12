//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
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
                    title: "Resume Offset",
                    value: $resumeOffset,
                    range: 0 ... 30,
                    step: 1
                )
                .valueFormatter {
                    $0.secondLabel
                }
            } footer: {
                Text("Resume content seconds before the recorded resume time")
            }
        }
        .navigationTitle("Native Player")
    }
}
