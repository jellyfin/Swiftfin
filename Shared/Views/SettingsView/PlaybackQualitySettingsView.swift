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

    #if os(tvOS)
    typealias PlatformPicker = ListRowMenu
    #else
    typealias PlatformPicker = Picker
    #endif

    @Default(.VideoPlayer.Playback.appMaximumResolution)
    private var appMaximumResolution
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
            Section(L10n.quality) {
                PlatformPicker(
                    L10n.resolution,
                    selection: $appMaximumResolution
                )

                PlatformPicker(
                    L10n.bitrate,
                    selection: $appMaximumBitrate
                )
            } footer: {
                Text(L10n.playbackQualityDescription)
            } learnMore: {
                LabeledContent(
                    L10n.auto,
                    value: L10n.birateAutoDescription
                )
                LabeledContent(
                    L10n.maximum,
                    value: L10n.bitrateMaxDescription(PlaybackBitrate.max.rawValue.formatted(.bitRate))
                )
            }
            .animation(.none, value: appMaximumBitrate)

            if appMaximumBitrate == .auto {
                Section {
                    PlatformPicker(
                        L10n.testSize,
                        selection: $appMaximumBitrateTest
                    )
                } header: {
                    Text(L10n.bitrateTest)
                } footer: {
                    Text(L10n.bitrateTestDisclaimer)
                }
            }

            Section(L10n.deviceProfile) {
                PlatformPicker(
                    L10n.compatibility,
                    selection: $compatibilityMode
                )

                if compatibilityMode == .custom {
                    ChevronButton(L10n.profiles) {
                        router.route(to: .customDeviceProfilesSettings)
                    }
                }
            } footer: {
                Text(L10n.deviceProfileDescription)
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
                Text(L10n.hdr)
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
