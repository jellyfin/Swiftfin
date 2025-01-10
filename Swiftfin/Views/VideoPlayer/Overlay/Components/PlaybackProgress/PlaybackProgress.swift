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

// TODO: bar color default to style
// TODO: possible issue with runTimeSeconds == 0

extension VideoPlayer.Overlay {

    struct PlaybackProgress: View {

        @Default(.VideoPlayer.Overlay.chapterSlider)
        private var chapterSlider
        @Default(.VideoPlayer.Overlay.sliderColor)
        private var sliderColor
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

        @State
        private var capsuleSliderSize = CGSize.zero
        @State
        private var sliderSize: CGSize = .zero

        private var progress: Double {
            scrubbedSeconds / manager.item.runTimeSeconds
        }

        // TODO: kept for future reference for trickplay scrubbing
        private var previewXOffset: CGFloat {
            let p = sliderSize.width * progress
            return clamp(p, min: 100, max: sliderSize.width - 100)
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
                    value: _scrubbedSeconds.wrappedValue,
                    total: manager.item.runTimeSeconds
                )
                .gesturePadding(30)
                .onEditingChanged { newValue in
                    isScrubbing = newValue
                }
                .foregroundStyle(sliderColor)
                .frame(maxWidth: isScrubbing ? nil : max(0, capsuleSliderSize.width - 30))
                .frame(height: isScrubbing ? 20 : 10)
            }
            .animation(.linear(duration: 0.05), value: scrubbedSeconds)
            .frame(height: 10)
        }

        @ViewBuilder
        private var thumbSlider: some View {
            ThumbSlider(
                value: _scrubbedSeconds.wrappedValue,
                total: manager.item.runTimeSeconds
            )
            .onEditingChanged { newValue in
                isScrubbing = newValue
            }
            .frame(height: 20)
        }

        var body: some View {
            VStack(spacing: 10) {
                if manager.item.isLiveStream {
                    liveIndicator
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Group {
                        switch sliderType {
                        case .capsule: capsuleSlider
                        case .thumb: thumbSlider
                        }
                    }
                    .trackingSize($sliderSize)

                    SplitTimeStamp()
                        .if(sliderType == .capsule) { view in
                            view.offset(y: isScrubbing ? 5 : 0)
                                .frame(maxWidth: isScrubbing ? nil : max(0, capsuleSliderSize.width - 30))
                        }
                }
            }
            .disabled(manager.state == .loadingItem)
            .frame(maxWidth: .infinity)
            .animation(.bouncy(duration: 0.4, extraBounce: 0.1), value: isScrubbing)
            // TODO: kept for future reference for trickplay/chapter image scrubbing
//            .overlay(alignment: .top) {
//                RoundedRectangle(cornerRadius: 16)
//                    .fill(Color.white.opacity(0.5))
//                    .aspectRatio(1.77, contentMode: .fill)
//                    .frame(width: 200)
//                    .position(x: previewXOffset, y: -75)
//                    .isVisible(isScrubbing)
//            }
        }
    }
}
