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
// TODO: bar color default to style
// TODO: live tv

extension VideoPlayer.PlaybackControls {

    struct PlaybackProgress: View {

        @Default(.VideoPlayer.Overlay.chapterSlider)
        private var chapterSlider

        @Toaster
        private var toaster: ToastProxy

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

        private let previewImageHeight: CGFloat = 200

        private var isScrubbing: Bool {
            get {
                containerState.isScrubbing
            }
            nonmutating set {
                containerState.isScrubbing = newValue
            }
        }

        var onPanScrubChanged: ((Bool) -> Void)?

        private var scrubbedProgress: Double {
            guard let runtime = manager.item.runtime, runtime > .zero else { return 0 }
            return scrubbedSecondsBox.value / runtime
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

        var body: some View {
            VStack(spacing: 10) {
                if manager.item.isLiveStream {
                    liveIndicator
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    CapsuleSlider(
                        value: $scrubbedSecondsBox.value.map(
                            getter: {
                                guard let runtime = manager.item.runtime, runtime > .zero else { return 0 }
                                return clamp(($0.seconds / runtime.seconds) * 100, min: 0, max: 100)
                            },
                            setter: { (manager.item.runtime ?? .zero) * ($0 / 100) }
                        ),
                        total: 100
                    )
                    .originProgress(originProgress(resolution: 100))
                    .onEditingChanged { isEditing in
                        if isEditing {
                            isScrubbing = true
                            onPanScrubChanged?(true)
                        } else {
                            onPanScrubChanged?(false)
                        }
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
                    .frame(height: 16)
                    .trackingSize($sliderSize)
                    .overlay {
                        CurrentSecondTick()
                            .allowsHitTesting(false)
                    }
                    .foregroundStyle(manager.state == .loadingItem ? .gray : .primary)
                    .disabled(manager.state == .loadingItem)

                    SplitTimeStamp()
                        .foregroundStyle(Color.white)
                }
            }
            .focused($isFocused)
            .foregroundStyle(isFocused ? Color.white : Color.gray.opacity(0.75))
            .animation(.easeInOut(duration: 0.2), value: isFocused)
            .overlay(alignment: .topLeading) {
                if isScrubbing, let previewImageProvider = manager.playbackItem?.previewImageProvider {
                    PreviewImageView(previewImageProvider: previewImageProvider)
                        .aspectRatio(videoSizeAspectRatio, contentMode: .fit)
                        .frame(height: previewImageHeight)
                        .posterBorder()
                        .cornerRadius(ratio: 1 / 30, of: \.width)
                        .offset(x: previewXOffset, y: -(previewImageHeight + 10))
                        .shadow(color: Color.black.opacity(0.5), radius: 4, x: 0, y: 4)
                }
            }
            .onChange(of: isFocused) { _, newValue in
                containerState.isProgressBarFocused = newValue
            }
        }
    }
}
