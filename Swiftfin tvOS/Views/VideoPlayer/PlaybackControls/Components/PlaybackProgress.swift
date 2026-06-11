//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
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

        @FocusState
        private var isFocused: Bool

        @State
        private var sliderSize: CGSize = .zero

        @Toaster
        private var toaster: ToastProxy

        private let previewImageHeight: CGFloat = 200

        private var sliderHeight: CGFloat {
            isScrubbing ? 20 : 14
        }

        private var isScrubbing: Bool {
            get {
                containerState.isScrubbing
            }
            nonmutating set {
                containerState.isScrubbing = newValue
            }
        }

        private var scrubbedProgress: Double {
            guard let runtime = manager.item.runtime, runtime > .zero else { return 0 }
            return scrubbedSecondsBox.value / runtime
        }

        private var currentProgress: Double? {
            guard isScrubbing,
                  let runtime = manager.item.runtime,
                  runtime > .zero
            else {
                return nil
            }

            let currentSeconds = containerState.scrubOriginSeconds ?? manager.seconds
            return clamp((currentSeconds / runtime) * 100, min: 0, max: 100)
        }

        private var videoSizeAspectRatio: CGFloat {
            guard let videoPlayerProxy = manager.proxy as? any VideoMediaPlayerProxy else {
                return 1.77
            }

            return clamp(videoPlayerProxy.videoSize.value.aspectRatio, min: 0.25, max: 4)
        }

        private var previewXOffset: CGFloat {
            let videoWidth = previewImageHeight * videoSizeAspectRatio
            let p = (sliderSize.width * scrubbedProgress) - (videoWidth / 2)
            return clamp(p, min: 0, max: sliderSize.width - videoWidth)
        }

        @ViewBuilder
        private var liveIndicator: some View {
            Text(L10n.live)
                .font(UIDevice.isTV ? .caption : .subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
                .background {
                    Capsule()
                        .fill(Color.gray)
                }
        }

        @ViewBuilder
        private var videoPlayerSlider: some View {
            VideoPlayerSlider(
                value: $scrubbedSecondsBox.value.map(
                    getter: {
                        guard let runtime = manager.item.runtime, runtime > .zero else { return 0 }
                        return clamp(($0.seconds / runtime.seconds) * 100, min: 0, max: 100)
                    },
                    setter: { (manager.item.runtime ?? .zero) * ($0 / 100) }
                ),
                currentProgress: currentProgress,
                total: 100,
                isScrollingEnabled: manager.playbackRequestStatus == .paused
            )
            .onEditingChanged { isEditing in
                if isEditing {
                    if containerState.scrubOriginSeconds == nil {
                        containerState.scrubOriginSeconds = manager.seconds
                    }
                    isScrubbing = true
                }
            }
            .if(chapterSlider) { view in
                if let chapters = manager.item.fullChapterInfo, chapters.isNotEmpty {
                    view.inverseMask { ChapterTrackMask(chapters: chapters, runtime: manager.item.runtime ?? .zero) }
                } else {
                    view
                }
            }
            .frame(height: sliderHeight)
            .trackingSize($sliderSize)
            .foregroundStyle(manager.state == .loadingItem ? .gray : .primary)
            .disabled(manager.state == .loadingItem)
        }

        @ViewBuilder
        private var previewImage: some View {
            if isScrubbing, let previewImageProvider = manager.playbackItem?.previewImageProvider {
                PreviewImageView(previewImageProvider: previewImageProvider)
                    .aspectRatio(videoSizeAspectRatio, contentMode: .fit)
                    .frame(height: previewImageHeight)
                    .posterBorder()
                    .cornerRadius(ratio: 1 / 30, of: \.width)
                    .offset(x: previewXOffset, y: -(previewImageHeight + 10))
                    .shadow(color: Color.black.opacity(0.5), radius: 10, x: 0, y: 4)
            }
        }

        var body: some View {
            VStack(spacing: 10) {
                if manager.item.isLiveStream {
                    liveIndicator
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    videoPlayerSlider

                    SplitTimeStamp()
                        .foregroundStyle(.white, Color.lightGray)
                }
            }
            .focused($isFocused)
            .foregroundStyle(Color.white.opacity(0.75))
            .overlay(alignment: .topLeading) {
                previewImage
            }
            .onChange(of: isFocused) { _, newValue in
                containerState.isProgressBarFocused = newValue
            }
            .onChange(of: containerState.isProgressBarFocused) { _, newValue in
                if newValue, !isFocused {
                    isFocused = true
                }
            }
        }
    }
}
