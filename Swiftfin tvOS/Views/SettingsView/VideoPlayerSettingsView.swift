//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
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
                        title: "Resume Offset",
                        subtitle: resumeOffset.secondLabel
                    )
                    .onSelect {
                        isPresentingResumeOffsetStepper = true
                    }
                } footer: {
                    Text("Resume content seconds before the recorded resume time")
                }

                Section {
                    ChevronButton(title: L10n.subtitleFont, subtitle: subtitleFontName)
                        .onSelect {
                            router.route(to: \.fontPicker, $subtitleFontName)
                        }
                } footer: {
                    Text("Settings only affect some subtitle types")
                }

                Section {

                    Toggle("Pause on background", isOn: $pauseOnBackground)
                    Toggle("Play on active", isOn: $playOnActive)
                }
            }
            .navigationTitle("Video Player")
            .blurFullScreenCover(isPresented: $isPresentingResumeOffsetStepper) {
                StepperView(
                    title: "Resume Offset",
                    description: "Resume content seconds before the recorded resume time",
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
