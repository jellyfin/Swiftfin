//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

// TODO: bar color default to style
// TODO: remove compact buttons?
// TODO: capsule scale on editing
// TODO: possible issue with runTimeSeconds == 0
// TODO: live tv

extension VideoPlayer.Overlay {

    struct PlaybackProgress: View {

        @Default(.VideoPlayer.Overlay.chapterSlider)
        private var chapterSlider
        @Default(.VideoPlayer.Overlay.playbackButtonType)
        private var playbackButtonType
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

        @ViewBuilder
        private var capsuleSlider: some View {
            AlternateLayoutView {
                Color.clear
                    .frame(height: 10)
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
                .frame(height: isScrubbing ? 20 : 10)
                .offset(y: isScrubbing ? 20 : 0)
            }
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
            VStack(alignment: .leading, spacing: 10) {
                switch sliderType {
                case .capsule: capsuleSlider
                case .thumb: thumbSlider
                }
                
                SplitTimeStamp()
                    .if(sliderType == .capsule) { view in
                        view.offset(y: isScrubbing ? 25 : 0)
                    }
            }
            .disabled(manager.state == .loadingItem)
        }
    }
}
