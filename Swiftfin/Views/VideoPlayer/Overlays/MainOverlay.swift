//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension VideoPlayer {

    struct MainOverlay: View {

        @Default(.VideoPlayer.Overlay.playbackButtonType)
        private var playbackButtonType

        @Environment(\.isPresentingOverlay)
        @Binding
        private var isPresentingOverlay
        @Environment(\.isScrubbing)
        @Binding
        private var isScrubbing: Bool

        @State
        private var safeAreaInsets: EdgeInsets = .zero

        @StateObject
        private var overlayTimer: TimerProxy = .init()

        var body: some View {
            ZStack {
                Color.clear
                    .allowsHitTesting(false)

                VStack {
                    Overlay.TopBarView()
                        .background {
                            OpacityLinearGradient {
                                (0, 0.9)
                                (1, 0)
                            }
                            .foregroundStyle(.black)
                            .visible(playbackButtonType == .compact)
                        }
                        .visible(!isScrubbing && isPresentingOverlay)

                    Spacer()
                        .allowsHitTesting(false)

                    Overlay.BottomBarView()
                        .if(UIDevice.isPad) { view in
                            view.edgePadding([.bottom, .horizontal])
                        }
                        .background {
                            OpacityLinearGradient {
                                (0, 0)
                                (0.5, 0.5)
                                (0.5, 0.9)
                            }
                            .foregroundStyle(.black)
                            .visible(isScrubbing || playbackButtonType == .compact)
                        }
                        .visible(isScrubbing || isPresentingOverlay)
                }

                if playbackButtonType == .large {
                    Overlay.LargePlaybackButtons()
                        .visible(!isScrubbing && isPresentingOverlay)
                }
            }
            .animation(.linear(duration: 0.1), value: isScrubbing)
            .environmentObject(overlayTimer)
            .background {
                Color.black
                    .opacity(!isScrubbing && playbackButtonType == .large && isPresentingOverlay ? 0.5 : 0)
                    .allowsHitTesting(false)
            }
            .onChange(of: isPresentingOverlay) { newValue in
                guard newValue, !isScrubbing else { return }
                overlayTimer.start(5)
            }
            .onChange(of: isScrubbing) { newValue in
                if newValue {
                    overlayTimer.stop()
                } else {
                    overlayTimer.start(5)
                }
            }
            .onChange(of: overlayTimer.isActive) { newValue in
                guard !newValue, !isScrubbing else { return }

//                withAnimation(.linear(duration: 0.3)) {
//                    isPresentingOverlay = false
//                }
            }
            .onSizeChanged { size, safeAreaInsets in
                print(size, safeAreaInsets)

                if size.isLandscape {
                    self.safeAreaInsets = .init(
                        top: 0,
                        leading: safeAreaInsets.leading,
                        bottom: 0,
                        trailing: safeAreaInsets.trailing
                    )
                } else {
                    self.safeAreaInsets = .init(
                        top: safeAreaInsets.top,
                        leading: 0,
                        bottom: safeAreaInsets.bottom,
                        trailing: 0
                    )
                }
            }
        }
    }
}
