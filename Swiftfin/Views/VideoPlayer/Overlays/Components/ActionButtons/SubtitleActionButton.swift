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

    struct Subtitles: View {

        @EnvironmentObject
        private var videoPlayerManager: VideoPlayerManager
        @EnvironmentObject
        private var videoPlayerProxy: VLCVideoPlayer.Proxy
//        @EnvironmentObject
//        private var viewModel: VideoPlayerViewModel

        private var systemImage: String {
//            if isAudioTrackSelected {
//                "captions.bubble.fill"
//            } else {
            "captions.bubble"
//            }
        }

        var body: some View {
            Menu(
                L10n.subtitles,
                systemImage: systemImage
            ) {
                Button("Test") {}
                Button("Test") {}
                Button("Test") {}
            }
//            Menu {
//                ForEach(viewModel.subtitleStreams.prepending(.none), id: \.index) { subtitleTrack in
//                    Button {
//                        videoPlayerManager.subtitleTrackIndex = subtitleTrack.index ?? -1
//                        videoPlayerProxy.setSubtitleTrack(.absolute(subtitleTrack.index ?? -1))
//                    } label: {
//                        if videoPlayerManager.subtitleTrackIndex == subtitleTrack.index ?? -1 {
//                            Label(subtitleTrack.displayTitle ?? .emptyDash, systemImage: "checkmark")
//                        } else {
//                            Text(subtitleTrack.displayTitle ?? .emptyDash)
//                        }
//                    }
//                }
//            } label: {
//                content(videoPlayerManager.subtitleTrackIndex != -1)
//                    .eraseToAnyView()
//            }
        }
    }
}
