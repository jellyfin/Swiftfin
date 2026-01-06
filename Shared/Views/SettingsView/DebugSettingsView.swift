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
                        "GPU",
                        value: DeviceGPU.displayTitle
                    )
                }

                Button {
                    LabeledContent(
                        "GPU Family",
                        value: DeviceGPU.family?.rawValue.description ?? "Unknown"
                    )
                }

                Button {
                    LabeledContent(
                        "Apple Silicon",
                        value: DeviceGPU.family?.isAppleSilicon == true ? L10n.yes : L10n.no
                    )
                }

                Button {
                    LabeledContent(
                        "Display Supports HDR",
                        value: DeviceGPU.isDisplayHDRCompatible ? L10n.yes : L10n.no
                    )
                }
            }

            Section("Video Codec Support") {
                Button {
                    LabeledContent(
                        VideoCodec.av1.displayTitle,
                        value: DeviceGPU.family?.supportsAV1Decode == true ? L10n.yes : L10n.no
                    )
                }

                Button {
                    LabeledContent(
                        VideoCodec.hevc.displayTitle,
                        value: DeviceGPU.family?.supportsHEVCDecode == true ? L10n.yes : L10n.no
                    )
                }

                Button {
                    LabeledContent(
                        VideoCodec.vp8.displayTitle,
                        value: DeviceGPU.family?.supportsVP8Decode == true ? L10n.yes : L10n.no
                    )
                }

                Button {
                    LabeledContent(
                        VideoCodec.vp9.displayTitle,
                        value: DeviceGPU.family?.supportsVP9Decode == true ? L10n.yes : L10n.no
                    )
                }

                Button {
                    LabeledContent(
                        VideoCodec.vvc.displayTitle,
                        value: DeviceGPU.family?.supportsVVCDecode == true ? L10n.yes : L10n.no
                    )
                }
            }

            Section("Video Range Support") {
                Button {
                    LabeledContent(
                        VideoRangeType.hdr10Plus.displayTitle,
                        value: DeviceGPU.family?.supportsHDR10Decode == true ? L10n.yes : L10n.no
                    )
                }

                Button {
                    LabeledContent(
                        VideoRangeType.hlg.displayTitle,
                        value: DeviceGPU.family?.supportsHLGDecode == true ? L10n.yes : L10n.no
                    )
                }

                Button {
                    LabeledContent(
                        VideoRangeType.dovi.displayTitle,
                        value: DeviceGPU.family?.supportsDolbyVisionDecode == true ? L10n.yes : L10n.no
                    )
                }
            }
            #endif
        }
        .navigationTitle("Debug")
    }
}
#endif
