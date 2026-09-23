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

        private struct GlassSliderStyle: SliderContainerStyle {

            func makeBody(configuration: SliderContainerStyleConfiguration) -> some View {
                CapsuleSliderStyle()
                    .makeBody(configuration: configuration)
                    .background {
                        // Glass must not composite or clip the expanding progress fill.
                        Color.clear
                            .backport
                            .glassEffect(.regular.interactive(false), in: .capsule)
                            .allowsHitTesting(false)
                    }
            }
        }

        @AdaptiveLayout
        private var viewLayout

        @Default(.VideoPlayer.Overlay.chapterSlider)
        private var chapterSlider

        @Environment(ViewState.self)
        private var viewState
        @Environment(\.accessibilityReduceMotion)
        private var reduceMotion
        @Environment(MediaSession.self)
        private var mediaSession
        @State
        private var currentTranslation: CGPoint = .zero

        @State
        private var sliderSize: CGSize = .zero

        private var isScrubbing: Bool {
            viewState.isScrubbing
        }

        private var isLoading: Bool {
            mediaSession.activity == .loading || mediaSession.playbackState.isBuffering
        }

        private var isSlowScrubbing: Bool {
            isScrubbing && (currentTranslation.y >= 60)
        }

        private var insetSliderWidth: CGFloat {
            guard sliderSize.width.isFinite else { return 0 }

            return max(0, sliderSize.width - viewLayout.edgePadding * 2)
        }

        private var previewXOffset: CGFloat {
            guard sliderSize.width.isFinite, sliderSize.width > 0 else { return 0 }

            let videoWidth = 85 * videoSizeAspectRatio
            let p = (sliderSize.width * scrubbedProgress) - (videoWidth / 2)

            return clamp(p, min: 0, max: max(0, sliderSize.width - videoWidth))
        }

        private var scrubbedProgress: Double {
            guard let runtime = mediaSession.item.runtime, runtime > .zero else { return 0 }

            let progress = scrubbedSeconds / runtime
            guard progress.isFinite else { return 0 }

            return clamp(progress, min: 0, max: 1)
        }

        private var scrubbedSeconds: Duration {
            viewState.scrubbedSeconds
        }

        private var videoSizeAspectRatio: CGFloat {
            guard let aspectRatio = (mediaSession.player as? any VideoMediaPlayer)?
                .videoState
                .videoSize
                .aspectRatio
            else {
                return 1.77
            }

            return clamp(aspectRatio, min: 0.25, max: 4)
        }

        private var sliderTotal: Double {
            let total = (mediaSession.item.runtime ?? .zero).seconds
            guard total.isFinite, total > 0 else { return 1 }

            return total
        }

        private var liveIndicator: some View {
            Text(L10n.live)
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

        private var slowScrubbingIndicator: some View {
            HStack {
                Image(systemName: "backward.fill")
                Text(L10n.slowScrubbing.localizedCapitalized)
                Image(systemName: "forward.fill")
            }
            .font(.caption)
        }

        private var capsuleSlider: some View {
            AlternateLayoutView {
                EmptyHitTestView()
                    .frame(height: 10)
                    .trackingSize($sliderSize)
            } content: {
                // Use scale effect, slider doesn't respond well to horizontal frame changes
                let xScale = insetSliderWidth > 0 ? max(1, sliderSize.width / insetSliderWidth) : 1

                SliderContainer(
                    value: Bindable(viewState).scrubbedSeconds.map(
                        getter: { $0.seconds },
                        setter: { .seconds($0) }
                    ),
                    total: sliderTotal,
                    isScrollingEnabled: mediaSession.canSeek
                )
                .translation($currentTranslation)
                .valueDamping(isSlowScrubbing ? 0.1 : 1)
                .gesturePadding(30)
                .onEditingChanged { newValue in
                    if newValue {
                        viewState.beginScrub()
                    } else {
                        viewState.commitScrub()
                    }
                }
                .onEditingCancelled { viewState.cancelScrub() }
                .sliderContainerStyle(GlassSliderStyle())
                .if(chapterSlider) { view in
                    view.ifLet(mediaSession.item.chapters) { view, chapters in
                        if chapters.isEmpty {
                            view
                        } else {
                            view.inverseMask { ChapterTrackMask(chapters: chapters, runtime: mediaSession.item.runtime ?? .zero) }
                        }
                    }
                }
                .frame(maxWidth: sliderSize != .zero ? insetSliderWidth : .infinity)
                .scaleEffect(x: isScrubbing ? xScale : 1, y: 1, anchor: .center)
                .frame(height: isScrubbing ? 20 : 10)
                .foregroundStyle(mediaSession.canSeek ? Color.white : Color.gray)
                .phaseAnimator(isLoading && !reduceMotion ? [false, true] : [false]) { content, dimmed in
                    content.opacity(dimmed ? 0.8 : 1)
                } animation: { _ in
                    .easeInOut(duration: 1.1)
                }
            }
            .animation(.linear(duration: 0.05), value: scrubbedSeconds)
            .frame(height: 10)
            .disabled(!mediaSession.canSeek)
        }

        var body: some View {
            VStack(spacing: 5) {
                if mediaSession.item.isLiveStream {
                    liveIndicator
                        .edgePadding(.horizontal)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    capsuleSlider
                        .trackingSize($sliderSize)

                    SplitTimeStamp()
                        .offset(y: isScrubbing ? 5 : 0)
                        .frame(maxWidth: isScrubbing ? nil : insetSliderWidth)
                }
            }
            .frame(maxWidth: .infinity)
            .animation(.bouncy(duration: 0.4, extraBounce: 0.1), value: isScrubbing)
            .overlay(alignment: .topLeading) {
                if isScrubbing, let previewImageProvider = mediaSession.playbackItem?.previewImageProvider {
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
                        .offset(y: viewLayout.edgePadding * 2)
                        .transition(.opacity.animation(.linear(duration: 0.1)))
                }
            }
            .onChange(of: isSlowScrubbing) {
                guard isScrubbing else { return }

                UIDevice.impact(.soft)
            }
        }
    }
}
