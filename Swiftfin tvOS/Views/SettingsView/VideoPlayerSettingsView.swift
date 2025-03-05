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

    @Default(.VideoPlayer.jumpBackwardLength)
    private var jumpBackwardLength
    @Default(.VideoPlayer.jumpForwardLength)
    private var jumpForwardLength
    @Default(.VideoPlayer.resumeOffset)
    private var resumeOffset

    @Default(.VideoPlayer.Transition.pauseOnBackground)
    private var pauseOnBackground
    @Default(.VideoPlayer.Transition.playOnActive)
    private var playOnActive

    @EnvironmentObject
    private var router: VideoPlayerSettingsCoordinator.Router

    @State
    private var isPresentingResumeOffsetStepper: Bool = false

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
                    )
                    .onSelect {
                        isPresentingResumeOffsetStepper = true
                    }
                } header: {
                    L10n.resume.text
                } footer: {
                    L10n.resumeOffsetDescription.text
                }

                Section {

                    ChevronButton(L10n.subtitleFont, subtitle: subtitleFontName)
                        .onSelect {
                            router.route(to: \.fontPicker, $subtitleFontName)
                        }
                } header: {
                    L10n.subtitles.text
                } footer: {
                    L10n.subtitlesDisclaimer.text
                }

                Section(L10n.playback) {
                    Toggle(L10n.pauseOnBackground, isOn: $pauseOnBackground)
                    Toggle(L10n.playOnActive, isOn: $playOnActive)
                }
                .navigationTitle(L10n.videoPlayer.text)
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
}
