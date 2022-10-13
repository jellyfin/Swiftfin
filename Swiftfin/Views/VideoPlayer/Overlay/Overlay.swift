//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import Sliders
import SwiftUI
import VLCUI

extension ItemVideoPlayer {

    struct Overlay: View {

        @Default(.VideoPlayer.Overlay.playbackButtonType)
        private var playbackButtonType

        @Environment(\.isScrubbing)
        @Binding
        private var isScrubbing: Bool
        @Environment(\.safeAreaInsets)
        private var safeAreaInsets
        @Environment(\.presentingPlaybackSettings)
        @Binding
        private var presentingPlaybackSettings

        var body: some View {
            ZStack {
                VStack {
                    TopBarView()
                        .padding(safeAreaInsets.mutating(\.trailing, to: 0))
                        .padding(.trailing, presentingPlaybackSettings ? 0 : safeAreaInsets.trailing)
                        .background {
                            LinearGradient(
                                stops: [
                                    .init(color: .black.opacity(0.9), location: 0),
                                    .init(color: .clear, location: 1),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .opacity(playbackButtonType == .compact ? 1 : 0)
                        }
                        .opacity(isScrubbing ? 0 : 1)

                    Spacer()
                        .allowsHitTesting(false)

                    BottomBarView()
                        .padding(safeAreaInsets.mutating(\.trailing, to: 0))
                        .padding(.trailing, presentingPlaybackSettings ? 0 : safeAreaInsets.trailing)
                        .background {
                            LinearGradient(
                                stops: [
                                    .init(color: .clear, location: 0),
                                    .init(color: .black.opacity(0.7), location: 0.5),
                                    .init(color: .black.opacity(0.9), location: 1),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .opacity(isScrubbing || playbackButtonType == .compact ? 1 : 0)
                        }
                }

                if playbackButtonType == .large {
                    LargePlaybackButtons()
                        .opacity(isScrubbing ? 0 : 1)
                }
            }
            .background {
                Color.black
                    .opacity(isScrubbing || (!isScrubbing && playbackButtonType != .large) ? 0 : 0.5)
                    .allowsHitTesting(false)
            }
            .animation(.linear(duration: 0.1), value: isScrubbing)
        }
    }
}
