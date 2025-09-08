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
// TODO: change split timestamp interaction to be split,
//       make slider gesture padding larger
// TODO: scrubbing snapping behaviors

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
        private var sliderSize: CGSize = .zero

        private var isScrubbing: Bool {
            get {
                containerState.isScrubbing
            }
            nonmutating set {
                containerState.isScrubbing = newValue
            }
        }

        private var previewXOffset: CGFloat {
            let videoWidth = 85 * videoSizeAspectRatio
            let p = (sliderSize.width * scrubbedProgress) - (videoWidth / 2)
            return clamp(p, min: 0, max: sliderSize.width - videoWidth)
        }

        private var progress: Double {
            scrubbedSeconds / (manager.item.runtime ?? .seconds(1))
        }

        private var scrubbedProgress: Double {
            guard let runtime = manager.item.runtime, runtime > .zero else { return 0 }
            return scrubbedSeconds / runtime
        }

        private var scrubbedSeconds: Duration {
            scrubbedSecondsBox.value
        }

        private var videoSizeAspectRatio: CGFloat {
            guard let videoPlayerProxy = manager.proxy as? any VideoMediaPlayerProxy else {
                return 1.77
            }

            return clamp(videoPlayerProxy.videoSize.value.aspectRatio, min: 0.25, max: 4)
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
                    .trackingSize($sliderSize)
            } content: {
                // Use scale effect, progress view implementation doesn't respond well to frame changes
                let xScale = max(1, sliderSize.width / (sliderSize.width - EdgeInsets.edgePadding * 2))

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
                .frame(maxWidth: sliderSize != .zero ? sliderSize.width - EdgeInsets.edgePadding * 2 : .infinity)
                .scaleEffect(x: isScrubbing ? xScale : 1, y: 1, anchor: .center)
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
                        .trackingSize($sliderSize)

                    SplitTimeStamp()
                        .offset(y: isScrubbing ? 5 : 0)
                        .frame(maxWidth: isScrubbing ? nil : max(0, sliderSize.width - EdgeInsets.edgePadding * 2))
                }
            }
            .frame(maxWidth: .infinity)
            .animation(.bouncy(duration: 0.4, extraBounce: 0.1), value: isScrubbing)
            .overlay(alignment: .topLeading) {
                if isScrubbing, let previewImageProvider = manager.playbackItem?.previewImageProvider {
                    PreviewImageView(previewImageProvider: previewImageProvider)
                        .aspectRatio(videoSizeAspectRatio, contentMode: .fit)
                        .frame(height: 85)
                        .posterBorder()
                        .cornerRadius(ratio: 1 / 30, of: \.width)
                        .offset(x: previewXOffset, y: -100)
                }
            }
        }
    }
}

// TODO: make option?
struct SliderTick: View {

    @EnvironmentObject
    private var manager: MediaPlayerManager

    @State
    private var activeSeconds: Duration = .zero

    var body: some View {
        if let runtime = manager.item.runtime, runtime > .zero {
            GeometryReader { proxy in
                AlternateLayoutView(alignment: .leading) {
                    Color.clear
                } content: {
                    Color.white
                        .frame(width: 1.5)
                        .offset(x: proxy.size.width * (activeSeconds / runtime) - 0.75)
                }
            }
            .assign(manager.secondsBox.$value, to: $activeSeconds)
        }
    }
}
