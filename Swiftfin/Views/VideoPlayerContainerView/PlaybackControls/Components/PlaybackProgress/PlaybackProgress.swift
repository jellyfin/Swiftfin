//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

// TODO: smooth out animation when done scrubbing
// TODO: enabled/disabled state

extension VideoPlayer.PlaybackControls {

    struct PlaybackProgress: View {

        @Default(.VideoPlayer.Overlay.chapterSlider)
        private var chapterSlider

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState
        @EnvironmentObject
        private var manager: MediaPlayerManager
        @EnvironmentObject
        private var scrubbedSecondsBox: PublishedBox<Duration>

        @State
        private var capsuleSliderSize: CGSize = .zero

        private var isScrubbing: Bool {
            get {
                containerState.isScrubbing
            }
            nonmutating set {
                containerState.isScrubbing = newValue
            }
        }

        private var progress: Double {
            scrubbedSeconds / (manager.item.runtime ?? .seconds(1))
        }

        private var scrubbedSeconds: Duration {
            scrubbedSecondsBox.value
        }

        @ViewBuilder
        private var liveIndicator: some View {
            Text("Live")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background {
                    Capsule()
                        .fill(Color.gray)
                }
        }

        @ViewBuilder
        private var capsuleSlider: some View {
            AlternateLayoutView {
                EmptyHitTestView()
                    .frame(height: 10)
                    .trackingSize($capsuleSliderSize)
            } content: {
                CapsuleSlider(
                    value: $scrubbedSecondsBox.value.map(
                        getter: { $0.seconds },
                        setter: { .seconds($0) }
                    ),
                    total: max(1, (manager.item.runtime ?? .zero).seconds)
                )
                .gesturePadding(30)
                .onEditingChanged { newValue in
                    isScrubbing = newValue
                }
//                .if(manager.item.fullChapterInfo.isNotEmpty) { view in
//                    view.mask(ChapterTrackMask(chapters: manager.item.fullChapterInfo))
//                }
                .frame(maxWidth: isScrubbing ? nil : max(0, capsuleSliderSize.width - EdgeInsets.edgePadding * 2))
                .frame(height: isScrubbing ? 20 : 10)
            }
            .animation(.linear(duration: 0.05), value: scrubbedSeconds)
            .frame(height: 10)
        }

        var body: some View {
            VStack(spacing: 10) {
                if manager.item.isLiveStream {
                    liveIndicator
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    capsuleSlider
                        .trackingSize($capsuleSliderSize)

                    SplitTimeStamp()
                        .offset(y: isScrubbing ? 5 : 0)
                        .frame(maxWidth: isScrubbing ? nil : max(0, capsuleSliderSize.width - EdgeInsets.edgePadding * 2))
                }
            }
            .frame(maxWidth: .infinity)
            .animation(.bouncy(duration: 0.4, extraBounce: 0.1), value: isScrubbing)
        }
    }
}
