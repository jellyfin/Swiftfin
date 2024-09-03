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
        @Environment(\.safeAreaInsets)
        @Binding
        private var safeAreaInsets

        @State
        private var actualSafeArea: EdgeInsets = .zero

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
                .edgePadding()

                if playbackButtonType == .large {
                    Overlay.LargePlaybackButtons()
                        .visible(!isScrubbing && isPresentingOverlay)
                }
            }
//            .debugOverlay()
            .padding(actualSafeArea)
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
            .onSizeChanged { newSize in
                if newSize.isPortrait {
                    actualSafeArea = .init(
                        vertical: min(safeAreaInsets.top, safeAreaInsets.bottom),
                        horizontal: 0
                    )
                } else {
                    actualSafeArea = .init(
                        vertical: 0,
                        horizontal: min(safeAreaInsets.leading, safeAreaInsets.trailing)
                    )
                }
            }
        }
    }
}
