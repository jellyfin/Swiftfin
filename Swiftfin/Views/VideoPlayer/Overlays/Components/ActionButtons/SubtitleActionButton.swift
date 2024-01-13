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
        @EnvironmentObject
        private var viewModel: VideoPlayerViewModel

        private var content: (Bool) -> any View

        var body: some View {
            Menu {
                ForEach(viewModel.subtitleStreams.prepending(.none), id: \.index) { subtitleTrack in
                    Button {
                        videoPlayerManager.subtitleTrackIndex = subtitleTrack.index ?? -1
                        videoPlayerProxy.setSubtitleTrack(.absolute(subtitleTrack.index ?? -1))
                    } label: {
                        if videoPlayerManager.subtitleTrackIndex == subtitleTrack.index ?? -1 {
                            Label(subtitleTrack.displayTitle ?? .emptyDash, systemImage: "checkmark")
                        } else {
                            Text(subtitleTrack.displayTitle ?? .emptyDash)
                        }
                    }
                }
            } label: {
                content(videoPlayerManager.subtitleTrackIndex != -1)
                    .eraseToAnyView()
            }
        }
    }
}

extension VideoPlayer.Overlay.ActionButtons.Subtitles {

    init(@ViewBuilder _ content: @escaping (Bool) -> any View) {
        self.content = content
    }
}
