//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

extension VideoPlayer.Overlay {

    struct BottomBarView: View {

        @Default(.VideoPlayer.Overlay.chapterSlider)
        private var chapterSlider
        @Default(.VideoPlayer.Overlay.playbackButtonType)
        private var playbackButtonType
        @Default(.VideoPlayer.Overlay.sliderType)
        private var sliderType

        @Environment(\.isScrubbing)
        @Binding
        private var isScrubbing: Bool

//        @EnvironmentObject
//        private var overlayTimer: DelayIntervalTimer
        @EnvironmentObject
        private var manager: MediaPlayerManager
        @EnvironmentObject
        private var scrubbedProgress: ProgressBox

        @ViewBuilder
        private var capsuleSlider: some View {
            CapsuleSlider(progress: $scrubbedProgress.progress)
                .isEditing(_isScrubbing.wrappedValue)
                .bottomContent {
                    SplitTimeStamp()
                        .padding(5)
                }
                .leadingContent {
                    if playbackButtonType == .compact {
                        SmallPlaybackButtons()
                            .padding(.trailing)
                            .disabled(isScrubbing)
                    }
                }
        }

        @ViewBuilder
        private var thumbSlider: some View {
            ThumbSlider(progress: $scrubbedProgress.progress)
                .isEditing(_isScrubbing.wrappedValue)
                .bottomContent {
                    SplitTimeStamp()
                        .padding(5)
                }
                .leadingContent {
                    if playbackButtonType == .compact {
                        SmallPlaybackButtons()
                            .padding(.trailing)
                            .disabled(isScrubbing)
                    }
                }
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                switch sliderType {
                case .capsule: capsuleSlider
                case .thumb: thumbSlider
                }
            }
            .disabled(manager.state == .loadingItem)
        }
    }
}
