//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer.PlaybackControls {

    struct SplitTimeStamp: View {

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState
        @EnvironmentObject
        private var manager: MediaPlayerManager
        @EnvironmentObject
        private var scrubbedSecondsBox: PublishedBox<Duration>

        @State
        private var contentSize: CGSize = .zero
        @State
        private var leadingTimestampSize: CGSize = .zero
        @State
        private var trailingTimestampSize: CGSize = .zero

        private var previewXOffset: CGFloat {
            let p = contentSize.width * scrubbedProgress - (leadingTimestampSize.width / 2)
            return clamp(p, min: 0, max: contentSize.width - (trailingTimestampSize.width + leadingTimestampSize.width))
        }

        private var scrubbedProgress: Double {
            guard let runtime = manager.item.runtime, runtime > .zero else { return 0 }
            return scrubbedSeconds / runtime
        }

        private var scrubbedSeconds: Duration {
            scrubbedSecondsBox.value
        }

        var body: some View {
            ZStack {
                if let runtime = manager.item.runtime {
                    Text(.zero - (runtime - scrubbedSeconds), format: .runtime)
                } else {
                    Text(verbatim: .emptyRuntime)
                }
            }
            .trackingSize($trailingTimestampSize)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .debugBackground()
            .overlay(alignment: .leading) {
                Text(scrubbedSeconds, format: .runtime)
                    .trackingSize($leadingTimestampSize)
                    .offset(x: previewXOffset)
            }
            .monospacedDigit()
            .trackingSize($contentSize)
        }
    }
}
