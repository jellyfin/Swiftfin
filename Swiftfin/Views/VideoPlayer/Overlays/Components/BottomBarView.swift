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

// TODO: rename
// TODO: bar color default to style
// TODO: remove compact buttons?
// TODO: timestamp handling
// TODO: capsule scale on editing

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
        @Environment(\.scrubbedSeconds)
        @Binding
        private var scrubbedSeconds: TimeInterval

        @EnvironmentObject
        private var manager: MediaPlayerManager

        @ViewBuilder
        private var capsuleSlider: some View {
            // TODO: possible issue with runTimeSeconds == 0
            CapsuleSlider(
                value: _scrubbedSeconds.wrappedValue,
                total: manager.item.runTimeSeconds
            )
            .onEditingChanged { newValue in
                isScrubbing = newValue
            }
            .frame(height: 30)
        }

        @ViewBuilder
        private var thumbSlider: some View {
            EmptyView()
//            ThumbSlider(progress: $scrubbedProgress.progress)
//                .isEditing(_isScrubbing.wrappedValue)
//                .bottomContent {
//                    SplitTimeStamp()
//                        .padding(5)
//                }
//                .leadingContent {
//                    if playbackButtonType == .compact {
//                        SmallPlaybackButtons()
//                            .padding(.trailing)
//                            .disabled(isScrubbing)
//                    }
//                }
        }

        var body: some View {
//            VStack(alignment: .leading, spacing: 0) {
//                switch sliderType {
//                case .capsule: capsuleSlider
//                case .thumb: thumbSlider
//                }
//            }
//            .disabled(manager.state == .loadingItem)
            
            capsuleSlider
        }
    }
}
