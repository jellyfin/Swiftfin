//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct PlaybackQualitySettingsView: View {

    @Default(.VideoPlayer.Playback.appMaximumBitrate)
    private var appMaximumBitrate
    @Default(.VideoPlayer.Playback.appMaximumBitrateTest)
    private var appMaximumBitrateTest
    @Default(.VideoPlayer.Playback.compatibilityMode)
    private var compatibilityMode

    @Router
    private var router

    var body: some View {
        Form {
            Section {
                CaseIterablePicker(
                    L10n.maximumBitrate,
                    selection: $appMaximumBitrate
                )
            } header: {
                Text(L10n.bitrateDefault)
            } footer: {
                VStack(alignment: .leading) {
                    Text(L10n.bitrateDefaultDescription)
                    LearnMoreButton(L10n.bitrateDefault) {
                        LabeledContent(
                            L10n.auto,
                            value: L10n.birateAutoDescription
                        )
                        LabeledContent(
                            L10n.bitrateMax,
                            value: L10n.bitrateMaxDescription(PlaybackBitrate.max.rawValue.formatted(.bitRate))
                        )
                    }
                }
            }
            .animation(.none, value: appMaximumBitrate)

            if appMaximumBitrate == .auto {
                Section {
                    CaseIterablePicker(
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

            Section {
                CaseIterablePicker(
                    L10n.compatibility,
                    selection: $compatibilityMode
                )
                .animation(.none, value: compatibilityMode)

                if compatibilityMode == .custom {
                    ChevronButton(L10n.profiles) {
                        router.route(to: .customDeviceProfileSettings)
                    }
                }
            } header: {
                Text(L10n.deviceProfile)
            } footer: {
                VStack(alignment: .leading) {
                    Text(L10n.deviceProfileDescription)
                    LearnMoreButton(L10n.deviceProfile) {
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
                }
            }
        }
        .animation(.linear, value: appMaximumBitrate)
        .animation(.linear, value: compatibilityMode)
        .navigationTitle(L10n.playbackQuality.localizedCapitalized)
    }
}
