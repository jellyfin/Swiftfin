//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct VideoPlayerSettingsView: View {

    @Default(.VideoPlayer.Subtitle.subtitleFontName)
    private var subtitleFontName

    @Default(.VideoPlayer.jumpBackwardInterval)
    private var jumpBackwardLength
    @Default(.VideoPlayer.jumpForwardInterval)
    private var jumpForwardLength
    @Default(.VideoPlayer.resumeOffset)
    private var resumeOffset

    @Router
    private var router

    // TODO: Update with correct settings once the tvOS PlayerUI is complete
    var body: some View {
        Form(systemImage: "tv") {

            Section(L10n.buttons) {
                JumpIntervalPicker(L10n.jumpBackwardLength, selection: $jumpBackwardLength)
                JumpIntervalPicker(L10n.jumpForwardLength, selection: $jumpForwardLength)
            }

            Section {
                Stepper(L10n.resumeOffset, value: $resumeOffset, in: 0 ... 30, step: 1, format: SecondFormatter()) {
                    LabeledContent {
                        Text(resumeOffset, format: SecondFormatter())
                    } label: {
                        Text(L10n.resumeOffset)
                    }
                }
            } header: {
                Text(L10n.resume)
            } footer: {
                Text(L10n.resumeOffsetDescription)
            }

            Section {
                ChevronButton(L10n.subtitleFont, subtitle: subtitleFontName) {
                    router.route(to: .fontPicker(selection: $subtitleFontName))
                }
            } header: {
                Text(L10n.subtitles)
            } footer: {
                Text(L10n.subtitlesDisclaimer)
            }
        }
        .navigationTitle(L10n.videoPlayer)
    }
}
