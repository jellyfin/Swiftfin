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
// TODO: remove compact buttons?
// TODO: capsule scale on editing
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
            let p = sliderSize.width * scrubbedProgress
            return clamp(p, min: 100, max: sliderSize.width - 100)
        }

        private var scrubbedProgress: Double {
            guard let runtime = manager.item.runtime, runtime > .zero else { return 0 }
            return scrubbedSeconds / runtime
        }

        private var scrubbedSeconds: Duration {
            scrubbedSecondsBox.value
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
            .onEditingChanged { isEditing in
                isScrubbing = isEditing
                print(isEditing)
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
            .scaleEffect(isFocused ? 1.0 : 0.95)
            .animation(.easeInOut(duration: 0.3), value: isFocused)
            .foregroundStyle(isFocused ? Color.white : Color.white.opacity(0.8))
        }
    }
}
