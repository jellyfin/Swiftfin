//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

// NOTE: All settings *MUST* be surrounded by DEBUG compiler conditional as usage site

#if DEBUG
struct DebugSettingsView: View {

    @Default(.sendProgressReports)
    private var sendProgressReports

    var body: some View {
        Form(systemImage: "ladybug") {

            Section("Settings") {
                Toggle("Send Progress Reports", isOn: $sendProgressReports)
            }

            #if DEBUG
            Section("Device Details") {
                Button {
                    LabeledContent(
                        "SoC & GPU",
                        value: PlaybackCapabilities.gpuName
                    )
                }

                Button {
                    LabeledContent(
                        "Device Reports HDR Capabilities",
                        value: PlaybackCapabilities.isDeviceHDRCapable ? L10n.yes : L10n.no
                    )
                }
            }

            Section("Video Codec Support") {
                Button {
                    LabeledContent(
                        VideoCodec.av1.displayTitle,
                        value: PlaybackCapabilities.supportsAV1 ? L10n.yes : L10n.no
                    )
                }

                Button {
                    LabeledContent(
                        VideoCodec.hevc.displayTitle,
                        value: PlaybackCapabilities.supportsHEVC ? L10n.yes : L10n.no
                    )
                }

                Button {
                    LabeledContent(
                        VideoCodec.vp9.displayTitle,
                        value: PlaybackCapabilities.supportsVP9 ? L10n.yes : L10n.no
                    )
                }
            }

            Section("Video Range Support") {
                Button {
                    LabeledContent(
                        VideoRangeType.hdr10Plus.displayTitle,
                        value: PlaybackCapabilities.supportsHDR10 ? L10n.yes : L10n.no
                    )
                }

                Button {
                    LabeledContent(
                        VideoRangeType.hlg.displayTitle,
                        value: PlaybackCapabilities.supportsHLG ? L10n.yes : L10n.no
                    )
                }

                Button {
                    LabeledContent(
                        VideoRangeType.dovi.displayTitle,
                        value: PlaybackCapabilities.supportsDolbyVision ? L10n.yes : L10n.no
                    )
                }
            }
            #endif
        }
        .navigationTitle("Debug")
    }
}
#endif
