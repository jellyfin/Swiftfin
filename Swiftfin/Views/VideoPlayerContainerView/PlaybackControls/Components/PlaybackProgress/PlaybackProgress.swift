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

// TODO: enabled/disabled state
// TODO: scrubbing snapping behaviors
//       - chapter boundaries
//       - current running time
// TODO: show chapter title under preview image
//       - have max width, on separate offset track

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
        private var currentTranslation: CGPoint = .zero

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

        private var isSlowScrubbing: Bool {
            isScrubbing && (currentTranslation.y >= 60)
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
        private var slowScrubbingIndicator: some View {
            HStack {
                Image(systemName: "backward.fill")
                Text("Slow Scrubbing")
                Image(systemName: "forward.fill")
            }
            .font(.caption)
        }

        @ViewBuilder
        private var capsuleSlider: some View {
            AlternateLayoutView {
                EmptyHitTestView()
                    .frame(height: 10)
                    .trackingSize($sliderSize)
            } content: {
                // Use scale effect, slider doesn't respond well to horizontal frame changes
                let xScale = max(1, sliderSize.width / (sliderSize.width - EdgeInsets.edgePadding * 2))

                CapsuleSlider(
                    value: $scrubbedSecondsBox.value.map(
                        getter: { $0.seconds },
                        setter: { .seconds($0) }
                    ),
                    total: max(1, (manager.item.runtime ?? .zero).seconds),
                    translation: $currentTranslation,
                    valueDamping: isSlowScrubbing ? 0.1 : 1
                )
                .gesturePadding(30)
                .onEditingChanged { newValue in
                    isScrubbing = newValue
                }
                .if(chapterSlider) { view in
                    view.ifLet(manager.item.fullChapterInfo) { view, chapters in
                        if chapters.isEmpty {
                            view
                        } else {
                            view.inverseMask { ChapterTrackMask(chapters: chapters, runtime: manager.item.runtime ?? .zero) }
                        }
                    }
                }
                .frame(maxWidth: sliderSize != .zero ? sliderSize.width - EdgeInsets.edgePadding * 2 : .infinity)
                .scaleEffect(x: isScrubbing ? xScale : 1, y: 1, anchor: .center)
                .frame(height: isScrubbing ? 20 : 10)
                .foregroundStyle(manager.state == .loadingItem ? .gray : .primary)
            }
            .animation(.linear(duration: 0.05), value: scrubbedSeconds)
            .frame(height: 10)
            .disabled(manager.state == .loadingItem)
        }

        var body: some View {
            VStack(spacing: 5) {
                if manager.item.isLiveStream {
                    liveIndicator
                        .edgePadding(.horizontal)
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
            .overlay(alignment: .bottom) {
                if isSlowScrubbing {
                    slowScrubbingIndicator
                        .offset(y: EdgeInsets.edgePadding * 2)
                        .transition(.opacity.animation(.linear(duration: 0.1)))
                }
            }
            .onChange(of: isSlowScrubbing) { _ in
                guard isScrubbing else { return }
                UIDevice.impact(.soft)
            }
        }
    }
}
