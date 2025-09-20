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

    @Router
    private var router

    var body: some View {
        Form {

            ChevronButton(L10n.gestures) {
                router.route(to: .gestureSettings)
            }

            // TODO: custom view for custom interval creation
//            CaseIterablePicker(L10n.jumpBackwardLength, selection: $jumpBackwardLength)

//            CaseIterablePicker(L10n.jumpForwardLength, selection: $jumpForwardLength)

            Section {

                BasicStepper(
                    L10n.resumeOffset,
                    value: $resumeOffset,
                    range: 0 ... 30,
                    step: 1,
                    formatter: SecondFormatter()
                )
            } footer: {
                Text(L10n.resumeOffsetDescription)
            }

            ButtonSection()

            SliderSection()

            SubtitleSection()

            TimestampSection()
        }
        .navigationTitle(L10n.videoPlayer)
    }
}
