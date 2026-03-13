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

    struct PlaybackProgress: PlatformView {

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

        #if os(iOS)
        @State
        private var currentTranslation: CGPoint = .zero
        #elseif os(tvOS)
        @Toaster
        private var toaster: ToastProxy

        var onPanScrubChanged: ((Bool) -> Void)?

        @FocusState
        private var isFocused: Bool
        #endif

        private var isScrubbing: Bool {
            get {
                containerState.isScrubbing
            }
            nonmutating set {
                containerState.isScrubbing = newValue
            }
        }

        private var scrubbedSeconds: Duration {
            scrubbedSecondsBox.value
        }

        private var scrubbedProgress: Double {
            guard let runtime = manager.item.runtime, runtime > .zero else { return 0 }
            return scrubbedSeconds / runtime
        }

        private var videoSizeAspectRatio: CGFloat {
            guard let videoPlayerProxy = manager.proxy as? any VideoMediaPlayerProxy else {
                return 1.77
            }

            return clamp(videoPlayerProxy.videoSize.value.aspectRatio, min: 0.25, max: 4)
        }

        #if os(iOS)
        private let previewImageHeight: CGFloat = 85
        #else
        private let previewImageHeight: CGFloat = 200
        #endif

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
                .padding(.horizontal, UIDevice.isTV ? 16 : 8)
                .padding(.vertical, UIDevice.isTV ? 4 : 2)
                .background {
                    Capsule()
                        .fill(Color.gray)
                }
        }

        #if os(iOS)
        private var isSlowScrubbing: Bool {
            isScrubbing && (currentTranslation.y >= 60)
        }

        private var progress: Double {
            scrubbedSeconds / (manager.item.runtime ?? .seconds(1))
        }

        @ViewBuilder
        private var slowScrubbingIndicator: some View {
            HStack {
                Image(systemName: "backward.fill")
                Text(L10n.slowScrubbing.localizedCapitalized)
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

        #elseif os(tvOS)
        private func originProgress(resolution: Double) -> Double? {
            guard let origin = containerState.scrubOriginSeconds,
                  let runtime = manager.item.runtime, runtime > .zero else { return nil }
            return clamp((origin.seconds / runtime.seconds) * resolution, min: 0, max: resolution)
        }
        #endif

        var iOSView: some View {
            #if os(iOS)
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
                        .frame(height: previewImageHeight)
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
            #endif
        }

        var tvOSView: some View {
            #if os(tvOS)
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
            #endif
        }
    }
}
