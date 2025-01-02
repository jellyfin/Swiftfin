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

    @EnvironmentObject
    private var router: SettingsCoordinator.Router

    var body: some View {
        Form {
            Section {
                CaseIterablePicker(
                    L10n.maximumBitrate,
                    selection: $appMaximumBitrate
                )
            } header: {
                L10n.bitrateDefault.text
            } footer: {
                VStack(alignment: .leading) {
                    Text(L10n.bitrateDefaultDescription)
                    LearnMoreButton(L10n.bitrateDefault) {
                        TextPair(
                            title: L10n.auto,
                            subtitle: L10n.birateAutoDescription
                        )
                        TextPair(
                            title: L10n.bitrateMax,
                            subtitle: L10n.bitrateMaxDescription(PlaybackBitrate.max.rawValue.formatted(.bitRate))
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
                    L10n.bitrateTest.text
                } footer: {
                    VStack(alignment: .leading) {
                        L10n.bitrateTestDisclaimer.text
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
                    ChevronButton(L10n.profiles)
                        .onSelect {
                            router.route(to: \.customDeviceProfileSettings)
                        }
                }
            } header: {
                Text(L10n.deviceProfile)
            } footer: {
                VStack(alignment: .leading) {
                    Text(L10n.deviceProfileDescription)
                    LearnMoreButton(L10n.deviceProfile) {
                        TextPair(
                            title: L10n.auto,
                            subtitle: L10n.autoDescription
                        )
                        TextPair(
                            title: L10n.compatible,
                            subtitle: L10n.compatibleDescription
                        )
                        TextPair(
                            title: L10n.direct,
                            subtitle: L10n.directDescription
                        )
                        TextPair(
                            title: L10n.custom,
                            subtitle: L10n.customDescription
                        )
                    }
                }
            }
        }
        .animation(.linear, value: appMaximumBitrate)
        .animation(.linear, value: compatibilityMode)
        .navigationTitle(L10n.playbackQuality)
    }
}
