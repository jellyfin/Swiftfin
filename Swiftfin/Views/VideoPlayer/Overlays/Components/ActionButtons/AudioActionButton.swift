//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
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
        @EnvironmentObject
        private var viewModel: VideoPlayerViewModel

        private var content: (Bool) -> any View

        var body: some View {
            Menu {
                ForEach(viewModel.audioStreams.prepending(.none), id: \.index) { audioTrack in
                    Button {
                        let newIndex = audioTrack.index ?? -1

                        // For online playback, we need to re-request from server
                        if let onlineManager = videoPlayerManager as? OnlineVideoPlayerManager {
                            onlineManager.switchAudioTrack(to: newIndex)
                        } else {
                            // For offline/downloaded content, just switch locally
                            videoPlayerManager.audioTrackIndex = newIndex
                            videoPlayerProxy.setAudioTrack(.absolute(newIndex))
                        }
                    } label: {
                        if videoPlayerManager.audioTrackIndex == audioTrack.index ?? -1 {
                            Label(audioTrack.displayTitle ?? .emptyDash, systemImage: "checkmark")
                        } else {
                            Text(audioTrack.displayTitle ?? .emptyDash)
                        }
                    }
                }
            } label: {
                content(videoPlayerManager.audioTrackIndex != -1)
                    .eraseToAnyView()
            }
        }
    }
}

extension VideoPlayer.Overlay.ActionButtons.Audio {

    init(@ViewBuilder _ content: @escaping (Bool) -> any View) {
        self.content = content
    }
}
