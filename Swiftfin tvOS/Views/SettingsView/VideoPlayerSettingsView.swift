//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
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

    @State
    private var isPresentingResumeOffsetStepper: Bool = false

    // TODO: Update with correct settings once the tvOS PlayerUI is complete
    var body: some View {
        SplitFormWindowView()
            .descriptionView {
                Image(systemName: "tv")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 400)
            }
            .contentView {

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
