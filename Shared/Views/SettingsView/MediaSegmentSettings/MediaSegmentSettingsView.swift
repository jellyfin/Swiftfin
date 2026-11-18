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

struct MediaSegmentSettingsView: View {

    #if os(tvOS)
    typealias PlatformPicker = ListRowMenu
    #else
    typealias PlatformPicker = Picker
    #endif

    @Default(.VideoPlayer.mediaSegments)
    private var configuration

    @Router
    private var router

    @ContentBuilder
    var body: some View {
        Form(systemImage: "forward.end") {
            Section(L10n.mediaSegments) {
                ForEach(MediaSegmentType.supportedCases, id: \.self) { type in
                    PlatformPicker(type.displayTitle, selection: $configuration[type])
                }
            } learnMore: {
                LabeledContent(
                    MediaSegmentAction.off.displayTitle,
                    value: MediaSegmentAction.off.description
                )

                LabeledContent(
                    MediaSegmentAction.ask.displayTitle,
                    value: MediaSegmentAction.ask.description
                )

                LabeledContent(
                    MediaSegmentAction.skip.displayTitle,
                    value: MediaSegmentAction.skip.description
                )
            }

            Section(L10n.configuration) {
                PlatformPicker(L10n.repeat, selection: $configuration.repeatMode)
            } learnMore: {
                LabeledContent(
                    MediaSegmentRepeatMode.once.displayTitle,
                    value: MediaSegmentRepeatMode.once.description
                )

                LabeledContent(
                    MediaSegmentRepeatMode.everyTime.displayTitle,
                    value: MediaSegmentRepeatMode.everyTime.description
                )
            }

            Section {
                ChevronButton(L10n.mediaTypes) {
                    router.route(to: .mediaSegmentItemTypes)
                }
            } footer: {
                Text(L10n.mediaSegmentMediaTypesDescription)
            }

            if configuration.actions.values.contains(.skip) {
                Section {
                    Stepper(L10n.skipDelay, value: $configuration.skipDelay, in: 0 ... 30, step: 1) {
                        LabeledContent(L10n.skipDelay) {
                            Text(configuration.skipDelay, format: SecondFormatter())
                                .foregroundStyle(.secondary)
                        }
                    }
                } footer: {
                    Text(L10n.skipDelayDescription)
                }

                if configuration.skipDelay > 0 {
                    Section {
                        #if os(tvOS)
                        ListRowMenu(L10n.shortSegments, subtitle: Text(configuration.shortSegmentAction.displayTitle)) {
                            Picker(L10n.shortSegments, selection: $configuration.shortSegmentAction, onlySupported: true)
                        }
                        #else
                        Picker(L10n.shortSegments, selection: $configuration.shortSegmentAction, onlySupported: true)
                        #endif
                    } footer: {
                        Text(L10n.shortSegmentsDescription)
                    }
                }
            }
        }
        .toolbarTitleDisplayMode(.inline)
        .navigationTitle(L10n.mediaSegments.localizedCapitalized)
    }
}
