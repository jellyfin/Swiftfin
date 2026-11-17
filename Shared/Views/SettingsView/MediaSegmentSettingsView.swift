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
                PlatformPicker(L10n.frequency, selection: $configuration.skipPolicy)
            } learnMore: {
                LabeledContent(
                    MediaSegmentSkipPolicy.once.displayTitle,
                    value: MediaSegmentSkipPolicy.once.description
                )

                LabeledContent(
                    MediaSegmentSkipPolicy.everyTime.displayTitle,
                    value: MediaSegmentSkipPolicy.everyTime.description
                )
            }

            Section {
                ChevronButton(L10n.mediaTypes) {
                    router.route(to: .mediaSegmentMediaTypes)
                }
            } footer: {
                Text(L10n.mediaSegmentMediaTypesDescription)
            }

            if configuration.actions.values.contains(.skip) {
                Section {
                    Stepper(
                        L10n.skipDelay,
                        value: $configuration.skipDelay.map(
                            getter: { Int($0.seconds) },
                            setter: { .seconds($0) }
                        ),
                        in: 0 ... 30,
                        step: 1
                    ) {
                        LabeledContent(L10n.skipDelay) {
                            Text(Int(configuration.skipDelay.seconds), format: SecondFormatter())
                                .foregroundStyle(.secondary)
                        }
                    }
                } footer: {
                    Text(L10n.skipDelayDescription)
                }

                if configuration.skipDelay > .zero {
                    Section {
                        PlatformPicker(L10n.shortSegments, selection: $configuration.shortSegmentAction)
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
