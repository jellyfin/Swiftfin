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
// TODO: timestamp handling
// TODO: capsule scale on editing
// TODO: possible issue with runTimeSeconds == 0
// TODO: live tv

extension VideoPlayer.Overlay {

    struct PlaybackProgressView: View {

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
            CapsuleSlider(
                value: _scrubbedSeconds.wrappedValue,
                total: manager.item?.runTimeSeconds ?? 1
            )
            .onEditingChanged { newValue in
                isScrubbing = newValue
            }
            .foregroundStyle(sliderColor)
            .frame(height: 10)
        }

        @ViewBuilder
        private var thumbSlider: some View {
            ThumbSlider(
                value: _scrubbedSeconds.wrappedValue,
                total: manager.item?.runTimeSeconds ?? 1
            )
            .onEditingChanged { newValue in
                isScrubbing = newValue
            }
            .frame(height: 20)
        }

        var body: some View {
            VStack(alignment: .leading) {
                switch sliderType {
                case .capsule: capsuleSlider
                case .thumb: thumbSlider
                }
                
                SplitTimeStamp()
            }
            .disabled(manager.state == .loadingItem)
        }
    }
}
