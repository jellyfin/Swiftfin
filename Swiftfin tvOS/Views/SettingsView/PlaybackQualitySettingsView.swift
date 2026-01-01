//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
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
                    Text(L10n.bitrateDefault)
                } footer: {
                    Text(L10n.bitrateDefaultDescription)
                }
                .animation(.none, value: appMaximumBitrate)

                if appMaximumBitrate == .auto {
                    Section {
                        ListRowMenu(L10n.testSize, selection: $appMaximumBitrateTest)
                    } footer: {
                        Text(L10n.bitrateTestDisclaimer)
                    }
                }

                Section {
                    ListRowMenu(L10n.compatibility, selection: $compatibilityMode)
                        .focused($focusedItem, equals: .compatibility)

                    if compatibilityMode == .custom {
                        ChevronButton(L10n.profiles) {
                            router.route(to: .customDeviceProfileSettings)
                        }
                    }
                } header: {
                    Text(L10n.deviceProfile)
                } footer: {
                    Text(L10n.deviceProfileDescription)
                }
            }
            .navigationTitle(L10n.playbackQuality.localizedCapitalized)
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
                LabeledContent(
                    L10n.auto,
                    value: L10n.birateAutoDescription
                )
                LabeledContent(
                    L10n.bitrateMax,
                    value: L10n.bitrateMaxDescription(PlaybackBitrate.max.rawValue.formatted(.bitRate))
                )
            }

        case .compatibility:
            LearnMoreModal {
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

        case nil:
            EmptyView()
        }
    }
}
