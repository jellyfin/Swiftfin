//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
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
                    L10n.bitrateDefaultDescription.text
                }
            }

            Section {
                CaseIterablePicker(
                    L10n.testSize,
                    selection: $appMaximumBitrateTest
                )
            } header: {
                L10n.bitrateTest.text
            } footer: {
                VStack(alignment: .leading, spacing: 8) {
                    L10n.bitrateTestDescription.text
                    L10n.bitrateTestDisclaimer.text
                }
            }
            Section {
                CaseIterablePicker(
                    L10n.compatibility,
                    selection: $compatibilityMode
                )
                ChevronButton(L10n.profiles)
                    .onSelect {
                        router.route(to: \.customDeviceProfileSettings)
                    }
            } header: {
                L10n.deviceProfile.text
            } footer: {
                VStack(alignment: .leading, spacing: 8) {
                    L10n.customDeviceProfileDescription.text
                    switch compatibilityMode {
                    case .direct, .custom:
                        L10n.mayResultInPlaybackFailure.text
                    case .auto, .compatible:
                        EmptyView()
                    }
                }
            }
        }
        .navigationTitle(L10n.playbackQuality)
    }
}
