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
    private var router: PlaybackQualitySettingsCoordinator.Router

    // MARK: - Focus Management

    @FocusState
    private var focusedItem: FocusableItem?

    private enum FocusableItem: Hashable {
        case maximumBitrate
        case compatibility
    }

    // MARK: - Body

    var body: some View {
        SplitFormWindowView()
            .descriptionView {
                descriptionView
            }
            .contentView {
                Section {
                    ListRowMenu(L10n.maximumBitrate, selection: $appMaximumBitrate)
                        .focused($focusedItem, equals: .maximumBitrate)
                } header: {
                    L10n.bitrateDefault.text
                } footer: {
                    L10n.bitrateDefaultDescription.text
                }
                .animation(.none, value: appMaximumBitrate)

                if appMaximumBitrate == .auto {
                    Section {
                        ListRowMenu(L10n.testSize, selection: $appMaximumBitrateTest)
                    } footer: {
                        L10n.bitrateTestDisclaimer.text
                    }
                }

                Section {
                    ListRowMenu(L10n.compatibility, selection: $compatibilityMode)
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

    // MARK: - Description View Icon

    private var descriptionView: some View {
        ZStack {
            Image(systemName: "play.rectangle.on.rectangle")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 400)

            focusedDescription
                .transition(.opacity.animation(.linear(duration: 0.2)))
        }
    }

    // MARK: - Description View on Focus

    @ViewBuilder
    private var focusedDescription: some View {
        switch focusedItem {
        case .maximumBitrate:
            LearnMoreModal {
                TextPair(
                    title: L10n.auto,
                    subtitle: L10n.birateAutoDescription
                )
                TextPair(
                    title: L10n.bitrateMax,
                    subtitle: L10n.bitrateMaxDescription(PlaybackBitrate.max.rawValue.formatted(.bitRate))
                )
            }

        case .compatibility:
            LearnMoreModal {
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

        case nil:
            EmptyView()
        }
    }
}
