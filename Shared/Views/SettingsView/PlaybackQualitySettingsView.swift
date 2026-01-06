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

    @StoredValue(.User.forceDVTranscode)
    private var forceDVTranscode
    @StoredValue(.User.forceHDRTranscode)
    private var forceHDRTranscode

    @Router
    private var router

    var body: some View {
        Form(systemImage: "play.rectangle.on.rectangle") {
            Section(L10n.bitrateDefault) {
                #if os(iOS)
                Picker(
                    L10n.maximumBitrate,
                    selection: $appMaximumBitrate
                )
                #else
                ListRowMenu(
                    L10n.maximumBitrate,
                    selection: $appMaximumBitrate
                )
                #endif
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
                    #if os(iOS)
                    Picker(
                        L10n.testSize,
                        selection: $appMaximumBitrateTest
                    )
                    #else
                    ListRowMenu(
                        L10n.testSize,
                        selection: $appMaximumBitrateTest
                    )
                    #endif
                } header: {
                    Text(L10n.bitrateTest)
                } footer: {
                    VStack(alignment: .leading) {
                        Text(L10n.bitrateTestDisclaimer)
                    }
                }
            }

            Section(L10n.deviceProfile) {
                #if os(iOS)
                Picker(
                    L10n.compatibility,
                    selection: $compatibilityMode
                )
                #else
                ListRowMenu(
                    L10n.compatibility,
                    selection: $compatibilityMode
                )
                #endif

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
                    L10n.forceDVTranscode,
                    isOn: $forceDVTranscode
                )
                Toggle(
                    L10n.forceHDRTranscode,
                    isOn: $forceHDRTranscode
                )
            } header: {
                /// Proper nouns. Do not localize.
                Text("HDR & Dolby Vision")
            } footer: {
                VStack(alignment: .leading) {
                    Text(L10n.forceDVHDRTranscodeMessage)
                    if !PlaybackCapabilities.isDeviceHDRCapable {
                        Label(L10n.deviceHDRWarning, systemImage: "exclamationmark.circle.fill")
                            .labelStyle(.sectionFooterWithImage(imageStyle: .orange))
                    }
                }
            }
        }
        .animation(.linear, value: appMaximumBitrate)
        .animation(.linear, value: compatibilityMode)
        .navigationTitle(L10n.playbackQuality.localizedCapitalized)
    }
}
