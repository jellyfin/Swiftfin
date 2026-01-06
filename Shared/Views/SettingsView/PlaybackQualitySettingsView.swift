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

struct PlaybackQualitySettingsView: View {

    @Default(.VideoPlayer.Playback.appMaximumBitrate)
    private var appMaximumBitrate
    @Default(.VideoPlayer.Playback.appMaximumBitrateTest)
    private var appMaximumBitrateTest
    @Default(.VideoPlayer.Playback.compatibilityMode)
    private var compatibilityMode

    @StoredValue(.User.transcodeOnSDRDisplay)
    private var transcodeOnSDRDisplay
    @StoredValue(.User.enableDOVIP5)
    private var enableDOVIP5

    @Router
    private var router

    var body: some View {
        Form(systemImage: "play.rectangle.on.rectangle") {
            Section(L10n.bitrateDefault) {
                Picker(
                    L10n.maximumBitrate,
                    selection: $appMaximumBitrate
                )
            } footer: {
                VStack(alignment: .leading) {
                    Text(L10n.bitrateDefaultDescription)
                }
            } learnMore: {
                LabeledContent(
                    L10n.auto,
                    value: L10n.birateAutoDescription
                )
                LabeledContent(
                    L10n.bitrateMax,
                    value: L10n.bitrateMaxDescription(PlaybackBitrate.max.rawValue.formatted(.bitRate))
                )
            }
            .animation(.none, value: appMaximumBitrate)

            if appMaximumBitrate == .auto {
                Section {
                    Picker(
                        L10n.testSize,
                        selection: $appMaximumBitrateTest
                    )
                } header: {
                    Text(L10n.bitrateTest)
                } footer: {
                    VStack(alignment: .leading) {
                        Text(L10n.bitrateTestDisclaimer)
                    }
                }
            }

            Section(L10n.deviceProfile) {
                Picker(
                    L10n.compatibility,
                    selection: $compatibilityMode
                )
                .animation(.none, value: compatibilityMode)

                if compatibilityMode == .custom {
                    ChevronButton(L10n.profiles) {
                        router.route(to: .customDeviceProfileSettings)
                    }
                }
            } footer: {
                VStack(alignment: .leading) {
                    Text(L10n.deviceProfileDescription)
                }
            } learnMore: {
                LabeledContent(
                    L10n.auto,
                    value: L10n.autoDescription
                )
                LabeledContent(
                    L10n.compatible,
                    value: L10n.compatibleDescription
                )
                LabeledContent(
                    L10n.directPlay,
                    value: L10n.directDescription
                )
                LabeledContent(
                    L10n.custom,
                    value: L10n.customDescription
                )
            }

            Section {
                Toggle(
                    "Force SDR on non-HDR displays",
                    isOn: $transcodeOnSDRDisplay
                )
                Toggle(
                    "Dolby Vision (P5)",
                    isOn: $enableDOVIP5
                )
            } header: {
                Text("HDR & Dolby Video")
            } footer: {
                Text("Dolby Vision (P5) will cause issues with Dolby Vision with HLG (8.4) using MKV.")
            }

            Section(L10n.device) {
                LabeledContent(
                    "GPU",
                    value: DeviceGPU.displayTitle
                )

                LabeledContent(
                    "GPU Family",
                    value: DeviceGPU.family?.rawValue.description ?? "Unknown"
                )

                LabeledContent(
                    "Apple Silicon",
                    value: DeviceGPU.family?.isAppleSilicon == true ? L10n.yes : L10n.no
                )

                LabeledContent(
                    "Display Supports HDR",
                    value: DeviceGPU.isDisplayHDRCompatible ? L10n.yes : L10n.no
                )
            }

            Section(L10n.capabilities) {
                LabeledContent(
                    VideoCodec.av1.displayTitle,
                    value: DeviceGPU.family?.supportsAV1Decode == true ? L10n.yes : L10n.no
                )
                LabeledContent(
                    VideoCodec.hevc.displayTitle,
                    value: DeviceGPU.family?.supportsHEVCDecode == true ? L10n.yes : L10n.no
                )
                LabeledContent(
                    VideoCodec.vp8.displayTitle,
                    value: DeviceGPU.family?.supportsVP8Decode == true ? L10n.yes : L10n.no
                )
                LabeledContent(
                    VideoCodec.vp9.displayTitle,
                    value: DeviceGPU.family?.supportsVP9Decode == true ? L10n.yes : L10n.no
                )
                LabeledContent(
                    VideoCodec.vvc.displayTitle,
                    value: DeviceGPU.family?.supportsVVCDecode == true ? L10n.yes : L10n.no
                )
            }

            Section {
                LabeledContent(
                    VideoRangeType.hdr10Plus.displayTitle,
                    value: DeviceGPU.family?.supportsHDR10Decode == true ? L10n.yes : L10n.no
                )
                LabeledContent(
                    VideoRangeType.hlg.displayTitle,
                    value: DeviceGPU.family?.supportsHLGDecode == true ? L10n.yes : L10n.no
                )
                LabeledContent(
                    VideoRangeType.dovi.displayTitle,
                    value: DeviceGPU.family?.supportsDolbyVisionDecode == true ? L10n.yes : L10n.no
                )
            }
        }
        .animation(.linear, value: appMaximumBitrate)
        .animation(.linear, value: compatibilityMode)
        .navigationTitle(L10n.playbackQuality.localizedCapitalized)
    }
}
