//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI
import VLCUI

extension VideoPlayer.Overlay.ActionButtons {

    struct PlaybackSpeedMenu: View {

        @EnvironmentObject
        private var overlayTimer: TimerProxy
        @EnvironmentObject
        private var videoPlayerManager: VideoPlayerManager
        @EnvironmentObject
        private var videoPlayerProxy: VLCVideoPlayer.Proxy

        private var content: () -> any View

        var body: some View {
            Menu {
                ForEach(PlaybackSpeed.allCases, id: \.self) { speed in
                    Button {
                        videoPlayerManager.playbackSpeed = speed
                        Task { @MainActor in
                            videoPlayerProxy.setRate(.absolute(Float(speed.rawValue)))
                        }
                    } label: {
                        if speed == videoPlayerManager.playbackSpeed {
                            Label(speed.displayTitle, systemImage: "checkmark")
                        } else {
                            Text(speed.displayTitle)
                        }
                    }
                }
            } label: {
                content().eraseToAnyView()
            }
        }
    }
}

extension VideoPlayer.Overlay.ActionButtons.PlaybackSpeedMenu {

    init(@ViewBuilder _ content: @escaping () -> any View) {
        self.content = content
    }
}
