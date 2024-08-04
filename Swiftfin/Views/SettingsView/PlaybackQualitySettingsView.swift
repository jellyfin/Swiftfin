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

    @Default(.VideoPlayer.Playback.customDeviceProfile)
    private var customDeviceProfile
    @Default(.VideoPlayer.Playback.customDeviceProfileAudio)
    private var customDeviceProfileAudio
    @Default(.VideoPlayer.Playback.customDeviceProfileVideo)
    private var customDeviceProfileVideo
    @Default(.VideoPlayer.Playback.customDeviceProfileContainers)
    private var customDeviceProfileContainers

    @EnvironmentObject
    private var router: SettingsCoordinator.Router

    var body: some View {
        Form {
            Section {
                CaseIterablePicker(
                    L10n.maximumBitrate,
                    selection: $appMaximumBitrate
                )

                if appMaximumBitrate == PlaybackBitrate.auto {
                    CaseIterablePicker(
                        L10n.testSize,
                        selection: $appMaximumBitrateTest
                    )
                }
            } header: {
                L10n.maximumBitrate.text
            } footer: {
                if appMaximumBitrate == PlaybackBitrate.auto {
                    Text(L10n.bitrateTestDescription)
                }
            }

            Section {
                CaseIterablePicker(
                    "Custom Profile",
                    selection: $customDeviceProfile
                )

                if customDeviceProfile != CustomDeviceProfileSelection.off {
                    ChevronButton(L10n.audio)
                        .onSelect {
                            router.route(to: \.customProfileAudioSelector, $customDeviceProfileAudio)
                        }

                    ChevronButton(L10n.video)
                        .onSelect {
                            router.route(to: \.customProfileVideoSelector, $customDeviceProfileVideo)
                        }

                    ChevronButton(L10n.containers)
                        .onSelect {
                            router.route(to: \.customProfileContainerSelector, $customDeviceProfileContainers)
                        }
                }
            } header: {
                Text("Device Profile")
            }
        }
        .navigationTitle("Playback Quality")
    }
}
