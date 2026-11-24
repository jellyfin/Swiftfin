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

    @ContentBuilder
    var body: some View {
        let showsSkipDelay = configuration.actions.values.contains(.skip)

        Form(systemImage: "forward.end") {
            Section(L10n.mediaSegments) {
                ForEach(MediaSegmentType.supportedCases, id: \.self) { type in
                    PlatformPicker(type.displayTitle, selection: $configuration[type])
                }
            } learnMore: {
                ForEach(MediaSegmentAction.allCases, id: \.self) { option in
                    LabeledContent(option.displayTitle, value: option.description)
                }
            }

            Section(L10n.configuration) {
                PlatformPicker(L10n.repeat, selection: $configuration.repeatMode)
            } learnMore: {
                ForEach(MediaSegmentRepeatMode.allCases, id: \.self) { option in
                    LabeledContent(option.displayTitle, value: option.description)
                }
            }

            if showsSkipDelay {
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
            }
        }
        .animation(.linear, value: showsSkipDelay)
        .toolbarTitleDisplayMode(.inline)
        .navigationTitle(L10n.mediaSegments.localizedCapitalized)
    }
}
