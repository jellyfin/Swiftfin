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
    private var router: PlaybackQualitySettingsCoordinator.Router

    // MARK: - Focus and State Management

    @FocusState
    private var focusedItem: FocusableItem?

    // MARK: - Body

    var body: some View {
        SplitFormWindowView()
            .descriptionView {
                focusedDescription
                    .padding()
            }
            .contentView {
                Section {
                    InlineEnumToggle(
                        title: L10n.maximumBitrate,
                        selection: $appMaximumBitrate
                    )
                    .focused($focusedItem, equals: .maximumBitrate)
                } header: {
                    L10n.bitrateDefault.text
                } footer: {
                    L10n.bitrateDefaultDescription.text
                }
                .animation(.none, value: appMaximumBitrate)

                if appMaximumBitrate == .auto {
                    Section {
                        InlineEnumToggle(
                            title: L10n.testSize,
                            selection: $appMaximumBitrateTest
                        )
                        .focused($focusedItem, equals: .testSize)
                    } footer: {
                        L10n.bitrateTestDisclaimer.text
                    }
                }

                Section {
                    InlineEnumToggle(
                        title: L10n.compatibility,
                        selection: $compatibilityMode
                    )
                    .focused($focusedItem, equals: .compatibility)

                    if compatibilityMode == .custom {
                        ChevronButton(L10n.profiles)
                            .onSelect {
                                router.route(to: \.customDeviceProfileSettings)
                            }
                    }
                } header: {
                    L10n.deviceProfile.text
                } footer: {
                    L10n.deviceProfileDescription.text
                }
            }
            .navigationTitle(L10n.playbackQuality)
    }

    // MARK: - Focusable Buttons

    private enum FocusableItem: Hashable {
        case maximumBitrate
        case testSize
        case compatibility
    }

    // MARK: - Update Description Based on Focus

    @ViewBuilder
    private var focusedDescription: some View {
        switch focusedItem {
        case .maximumBitrate:
            LearnMoreView(L10n.bitrateDefault) {
                TextPair(
                    title: L10n.auto,
                    subtitle: L10n.birateAutoDescription
                )
                TextPair(
                    title: L10n.bitrateMax,
                    subtitle: L10n.bitrateMaxDescription(PlaybackBitrate.max.rawValue.formatted(.bitRate))
                )
            }

        case .testSize:
            LearnMoreView(L10n.bitrateTest) {
                TextPair(
                    title: L10n.testSize,
                    subtitle: L10n.bitrateTestDescription
                )
            }

        case .compatibility:
            LearnMoreView(L10n.deviceProfile) {
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

        default:
            Image(systemName: "play.rectangle.on.rectangle")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 400)
        }
    }
}
