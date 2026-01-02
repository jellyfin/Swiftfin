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

    @Default(.VideoPlayer.jumpBackwardInterval)
    private var jumpBackwardLength
    @Default(.VideoPlayer.jumpForwardInterval)
    private var jumpForwardLength
    @Default(.VideoPlayer.resumeOffset)
    private var resumeOffset

    @Router
    private var router

    @State
    private var isPresentingResumeOffsetStepper: Bool = false

    // TODO: Update with correct settings once the tvOS PlayerUI is complete
    var body: some View {
        Form(systemImage: "tv") {

            Section(L10n.buttons) {
                JumpIntervalPicker(L10n.jumpBackwardLength, selection: $jumpBackwardLength)
                JumpIntervalPicker(L10n.jumpForwardLength, selection: $jumpForwardLength)
            }

            Section {
                ChevronButton(
                    L10n.offset,
                    subtitle: resumeOffset.secondLabel
                ) {
                    isPresentingResumeOffsetStepper = true
                }
            } header: {
                Text(L10n.resume)
            } footer: {
                Text(L10n.resumeOffsetDescription)
            }

            TrackConfigurationSection()
        }
        .navigationTitle(L10n.videoPlayer.localizedCapitalized)
        .blurredFullScreenCover(isPresented: $isPresentingResumeOffsetStepper) {
            StepperView(
                title: L10n.resumeOffsetTitle,
                description: L10n.resumeOffsetDescription,
                value: $resumeOffset,
                range: 0 ... 30,
                step: 1
            )
            .valueFormatter {
                $0.secondLabel
            }
            .onCloseSelected {
                isPresentingResumeOffsetStepper = false
            }
        }
    }
}
