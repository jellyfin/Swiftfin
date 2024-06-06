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

    // TODO: Organize

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

    var body: some View {
        Form {

            ChevronButton(L10n.gestures)
                .onSelect {
                    router.route(to: \.gestureSettings)
                }

            CaseIterablePicker(L10n.jumpBackwardLength, selection: $jumpBackwardLength)

            CaseIterablePicker(L10n.jumpForwardLength, selection: $jumpForwardLength)

            Section {

                BasicStepper(
                    title: L10n.resumeOffset,
                    value: $resumeOffset,
                    range: 0 ... 30,
                    step: 1
                )
                .valueFormatter {
                    $0.secondLabel
                }
            } footer: {
                Text(L10n.resumeOffsetDescription)
            }

            ButtonSection()

            SliderSection()

            SubtitleSection()

            TimestampSection()

            Section(L10n.transition) {

                Toggle(L10n.pauseOnBackground, isOn: $pauseOnBackground)
                Toggle(L10n.playOnActive, isOn: $playOnActive)
            }
        }
        .navigationTitle(L10n.videoPlayer)
    }
}
