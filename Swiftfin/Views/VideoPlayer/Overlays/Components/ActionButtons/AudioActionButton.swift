//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI
import VLCUI

extension VideoPlayer.Overlay.ActionButtons {

    struct Audio: View {

        @EnvironmentObject
        private var videoPlayerManager: VideoPlayerManager
        @EnvironmentObject
        private var videoPlayerProxy: VLCVideoPlayer.Proxy
//        @EnvironmentObject
//        private var viewModel: VideoPlayerViewModel

        private var systemImage: String {
//            if isAudioTrackSelected {
//                "speaker.wave.2.fill"
//            } else {
            "speaker.wave.2"
//            }
        }

        var body: some View {
            Menu(
                "Audio",
                systemImage: systemImage
            ) {

                Button("Test") {}
                Button("Test") {}
                Button("Test") {}

//                ForEach(viewModel.audioStreams.prepending(.none), id: \.index) { audioTrack in
//                    Button {
//                        videoPlayerManager.audioTrackIndex = audioTrack.index ?? -1
//                        videoPlayerProxy.setAudioTrack(.absolute(audioTrack.index ?? -1))
//                    } label: {
//                        if videoPlayerManager.audioTrackIndex == audioTrack.index ?? -1 {
//                            Label(audioTrack.displayTitle ?? .emptyDash, systemImage: "checkmark")
//                        } else {
//                            Text(audioTrack.displayTitle ?? .emptyDash)
//                        }
//                    }
//                }
            }
            .transition(.scale.animation(.bouncy))
//            .id(isAspectFilled)
        }
    }
}
