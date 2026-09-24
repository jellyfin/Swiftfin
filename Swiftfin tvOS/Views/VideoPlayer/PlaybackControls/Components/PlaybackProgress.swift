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

        @Environment(ViewState.self)
        private var viewState
        @EnvironmentObject
        private var manager: MediaPlayerManager
        @EnvironmentObject
        private var scrubbedSecondsBox: PublishedBox<Duration>

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
                viewState.isScrubbing
            }
            nonmutating set {
                viewState.isScrubbing = newValue
            }
        }

        private var scrubbedProgress: Double {
            guard let runtime = manager.item.runtime, runtime > .zero else { return 0 }

            let progress = scrubbedSecondsBox.value / runtime
            guard progress.isFinite else { return 0 }

            return clamp(progress, min: 0, max: 1)
        }

        private var currentProgress: Double? {
            guard isScrubbing,
                  let runtime = manager.item.runtime,
                  runtime > .zero
            else {
                return nil
            }

            let currentSeconds = viewState.scrubOriginSeconds ?? manager.seconds
            let progress = (currentSeconds / runtime) * 100
            guard progress.isFinite else { return nil }

            return clamp(progress, min: 0, max: 100)
        }

        private var videoSizeAspectRatio: CGFloat {
            guard let aspectRatio = (manager.proxy as? any VideoMediaPlayerProxy)?
                .videoSize
                .value
                .aspectRatio
            else {
                return 1.77
            }

            return clamp(aspectRatio, min: 0.25, max: 4)
        }

        private var previewXOffset: CGFloat {
            guard sliderSize.width.isFinite, sliderSize.width > 0 else { return 0 }

            let videoWidth = previewImageHeight * videoSizeAspectRatio
            let p = (sliderSize.width * scrubbedProgress) - (videoWidth / 2)
            return clamp(p, min: 0, max: max(0, sliderSize.width - videoWidth))
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
            SliderContainer(
                value: $scrubbedSecondsBox.value.map(
                    getter: {
                        guard let runtime = manager.item.runtime, runtime > .zero else { return 0 }

                        let seconds = $0.seconds
                        let runtimeSeconds = runtime.seconds
                        guard seconds.isFinite, runtimeSeconds.isFinite, runtimeSeconds > 0 else { return 0 }

                        return clamp((seconds / runtimeSeconds) * 100, min: 0, max: 100)
                    },
                    setter: {
                        guard $0.isFinite else { return .zero }
                        return (manager.item.runtime ?? .zero) * (clamp($0, min: 0, max: 100) / 100)
                    }
                ),
                total: 100,
                isScrollingEnabled: manager.playbackRequestStatus == .paused && manager.state != .loadingItem,
                originProgress: currentProgress
            )
            .onEditingChanged { isEditing in
                if isEditing {
                    if viewState.scrubOriginSeconds == nil {
                        viewState.scrubOriginSeconds = manager.seconds
                    }
                    isScrubbing = true
                }
            }
            .sliderContainerStyle(.capsule(showsProgressWhenUnfocused: false))
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
            .coordinatedFocus(ViewState.Focus.progress)
            .onReceive(
                viewState.focusCoordinator.$focusedIDs
                    .map { $0.contains(ViewState.Focus.progress) }
                    .removeDuplicates()
                    .dropFirst()
            ) { isFocused in
                if !isFocused {
                    viewState.cancelScrub()
                }
            }
            .foregroundStyle(Color.white.opacity(0.75))
            .overlay(alignment: .topLeading) {
                previewImage
            }
        }
    }
}
