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

    @Default(.isLiquidGlassEnabled)
    private var isLiquidGlassEnabled
    @Default(.sendProgressReports)
    private var sendProgressReports

    var body: some View {
        Form(systemImage: "ladybug") {

            Section("Settings") {
                Toggle("Send Progress Reports", isOn: $sendProgressReports)
            }

            Section {
                Toggle("Liquid Glass", isOn: $isLiquidGlassEnabled)
            } footer: {
                Text("Requires app restart to take effect.")
            }

            Section("Device Details") {
                LabeledContent(
                    "SoC & GPU",
                    value: PlaybackCapabilities.gpuName
                )

                LabeledContent(
                    "Device Reports HDR Capabilities",
                    value: PlaybackCapabilities.isDeviceHDRCapable ? L10n.yes : L10n.no
                )
            }

            Section("Video Codec Support") {
                LabeledContent(
                    VideoCodec.av1.displayTitle,
                    value: PlaybackCapabilities.supportsAV1 ? L10n.yes : L10n.no
                )

                LabeledContent(
                    VideoCodec.hevc.displayTitle,
                    value: PlaybackCapabilities.supportsHEVC ? L10n.yes : L10n.no
                )

                LabeledContent(
                    VideoCodec.vp9.displayTitle,
                    value: PlaybackCapabilities.supportsVP9 ? L10n.yes : L10n.no
                )
            }

            Section("Video Range Support") {
                LabeledContent(
                    VideoRangeType.hdr10Plus.displayTitle,
                    value: PlaybackCapabilities.supportsHDR10 ? L10n.yes : L10n.no
                )

                LabeledContent(
                    VideoRangeType.hlg.displayTitle,
                    value: PlaybackCapabilities.supportsHLG ? L10n.yes : L10n.no
                )

                LabeledContent(
                    VideoRangeType.dovi.displayTitle,
                    value: PlaybackCapabilities.supportsDolbyVision ? L10n.yes : L10n.no
                )
            }
        }
        .labeledContentStyle(.focusable)
        .navigationTitle("Debug")
    }
}
#endif
