//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension VideoPlayer.Overlay.ActionButtons {

    struct Subtitles: View {

        @EnvironmentObject
        private var manager: MediaPlayerManager

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
                Section(L10n.subtitles) {
//                    Button("Test") {}
//                    Button("Test") {}
//                    Button("Test") {}

                    ForEach(manager.playbackItem.subtitleStreams.prepending(.none), id: \.index) { stream in
                        Button {
                            manager.playbackItem.selectedSubtitleStreamIndex = stream.index ?? -1
                            manager.proxy.set(subtitleStream: stream)
                        } label: {
                            if manager.playbackItem.selectedSubtitleStreamIndex == stream.index {
                                Label(stream.displayTitle ?? .emptyDash, systemImage: "checkmark")
                            } else {
                                Text(stream.displayTitle ?? .emptyDash)
                            }
                        }
                    }
                }
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
