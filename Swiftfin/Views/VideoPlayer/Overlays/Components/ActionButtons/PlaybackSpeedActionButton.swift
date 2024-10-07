//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer.Overlay.ActionButtons {

    struct PlaybackSpeedMenu: View {

        @EnvironmentObject
        private var videoPlayerManager: MediaPlayerManager
//        @EnvironmentObject
//        private var videoPlayerProxy: VLCVideoPlayer.Proxy

        var body: some View {
            Menu(
                L10n.playbackSpeed,
                systemImage: "speedometer"
            ) {
                Section(L10n.playbackSpeed) {
                    Button("Test") {}
                    Button("Test") {}
                    Button("Test") {}
                }
            }

//            Menu {
//                ForEach(PlaybackSpeed.allCases, id: \.self) { speed in
//                    Button {
            ////                        videoPlayerManager.playbackSpeed = speed
            ////                        videoPlayerProxy.setRate(.absolute(Float(speed.rawValue)))
//                    } label: {
//                        if speed == videoPlayerManager.playbackSpeed {
//                            Label(speed.displayTitle, systemImage: "checkmark")
//                        } else {
//                            Text(speed.displayTitle)
//                        }
//                    }
//                }
//            } label: {
//                content().eraseToAnyView()
//            }
        }
    }
}
