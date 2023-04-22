//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct NativeVideoPlayerSettingsView: View {

    @Default(.VideoPlayer.Native.fMP4Container)
    private var fMP4Container
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
                    $0.secondFormat
                }
            } footer: {
                Text("Resume content seconds before the recorded resume time")
            }

            Section {

                Toggle("fMP4 Container", isOn: $fMP4Container)
            } footer: {
                Text("Use fMP4 container to allow hevc content on supported devices")
            }
        }
        .navigationTitle("Native Player")
    }
}
