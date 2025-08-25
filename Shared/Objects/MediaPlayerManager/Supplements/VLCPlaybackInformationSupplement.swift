//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI
import VLCUI

// TODO: finish

struct VLCPlaybackInformationSupplement: MediaPlayerSupplement {

    let displayTitle: String = "Playback Info"
    let id: String = "VLCPlaybackInformation"

    var videoPlayerBody: some PlatformView {
        PlaybackInformationView()
    }

    struct PlaybackInformationView: PlatformView {

        struct _View: View {

            @ObservedObject
            var proxy: VLCMediaPlayerProxy

            @State
            private var currentPlaybackInformation: VLCVideoPlayer.PlaybackInformation? = nil

            var body: some View {
                ZStack {
                    if let currentPlaybackInformation {
                        LabeledContent("Displayed Pictures", value: "\(currentPlaybackInformation.numberOfDisplayedPictures)")
                    } else {
                        Color.green
                            .opacity(0.2)
                    }
                }
//                .assign(proxy.playbackInformation.$value, to: $currentPlaybackInformation)
            }
        }

        @EnvironmentObject
        private var manager: MediaPlayerManager

        var iOSView: some View {
            if let vlcProxy = manager.proxy as? VLCMediaPlayerProxy {
                _View(proxy: vlcProxy)
            } else {
                Color.red
                    .opacity(0.2)
            }
        }

        var tvOSView: some View { EmptyView() }
    }
}
