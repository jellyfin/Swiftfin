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

    @Default(.VideoPlayer.jumpBackwardInterval)
    private var jumpBackwardLength
    @Default(.VideoPlayer.jumpForwardInterval)
    private var jumpForwardLength
    @Default(.VideoPlayer.resumeOffset)
    private var resumeOffset
    @Default(.VideoPlayer.videoPlayerType)
    private var videoPlayerType

    private var isVLC: Bool {
        videoPlayerType == .swiftfin
    }

    @Router
    private var router

    var body: some View {
        Form {

            // MARK: Player Controls

            if isVLC {
                Section(L10n.controls) {
                    ChevronButton(L10n.gestures) {
                        router.route(to: .gestureSettings)
                    }

                    //            CaseIterablePicker(L10n.jumpBackwardLength, selection: $jumpBackwardLength)
                    //            CaseIterablePicker(L10n.jumpForwardLength, selection: $jumpForwardLength)
                }
            }

            // MARK: Resume Offset Customization (Shared)

            Section {
                BasicStepper(
                    L10n.resumeOffset,
                    value: $resumeOffset,
                    range: 0 ... 30,
                    step: 1,
                    formatter: SecondFormatter()
                )
            } header: {
                Text(L10n.resumeOffset)
            } footer: {
                Text(L10n.resumeOffsetDescription)
            }

            // MARK: Player Customizations

            if isVLC {
                ButtonSection()
                SliderSection()
                SubtitleSection()
                TimestampSection()
                TransitionSection()
            }
        }
        .navigationTitle(L10n.videoPlayer.localizedCapitalized)
    }
}
