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

// TODO: bar color default to style
// TODO: remove compact buttons?
// TODO: possible issue with runTimeSeconds == 0
// TODO: live tv

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

        @Toaster
        private var toaster: ToastProxy

        var onPanScrubChanged: ((Bool) -> Void)?

        @FocusState
        private var isFocused: Bool

        @State
        private var sliderSize = CGSize.zero

        private var isScrubbing: Bool {
            get {
                containerState.isScrubbing
            }
            nonmutating set {
                containerState.isScrubbing = newValue
            }
        }

        private var previewXOffset: CGFloat {
            let videoWidth = 200 * videoSizeAspectRatio
            let p = (sliderSize.width * scrubbedProgress) - (videoWidth / 2)
            return clamp(p, min: 0, max: sliderSize.width - videoWidth)
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

        private var liveIndicator: some View {
            Text("Live")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
                .background {
                    Capsule()
                        .fill(Color.gray)
                }
        }

        private func originProgress(resolution: Double) -> Double? {
            guard let origin = containerState.scrubOriginSeconds,
                  let runtime = manager.item.runtime, runtime > .zero else { return nil }
            return clamp((origin.seconds / runtime.seconds) * resolution, min: 0, max: resolution)
        }

        @ViewBuilder
        private var capsuleSlider: some View {

            let resolution: Double = 100

            CapsuleSlider(
                value: $scrubbedSecondsBox.value.map(
                    getter: {
                        guard let runtime = manager.item.runtime, runtime > .zero else { return 0 }
                        return clamp(($0.seconds / runtime.seconds) * resolution, min: 0, max: resolution)
                    },
                    setter: { (manager.item.runtime ?? .zero) * ($0 / resolution) }
                ),
                total: resolution
            )
            .originProgress(originProgress(resolution: resolution))
            .onEditingChanged { isEditing in
                if isEditing {
                    isScrubbing = true
                    onPanScrubChanged?(true)
                } else {
                    onPanScrubChanged?(false)
                }
            }
            .frame(height: 50)
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
                }
            }
            .focused($isFocused)
            .scaleEffect(isFocused ? 1.025 : 1.0)
            .foregroundStyle(isFocused ? Color.white : Color.white.opacity(0.8))
            .animation(.easeInOut(duration: 0.2), value: isFocused)
            .overlay(alignment: .topLeading) {
                if isScrubbing, let previewImageProvider = manager.playbackItem?.previewImageProvider {
                    PreviewImageView(previewImageProvider: previewImageProvider)
                        .aspectRatio(videoSizeAspectRatio, contentMode: .fit)
                        .frame(height: 200)
                        .posterBorder()
                        .cornerRadius(ratio: 1 / 30, of: \.width)
                        .offset(x: previewXOffset, y: -220)
                        .shadow(color: Color.black.opacity(0.5), radius: 4, x: 0, y: 4)
                }
            }
            .onChange(of: isFocused) { _, newValue in
                containerState.isProgressBarFocused = newValue
            }
        }
    }
}
