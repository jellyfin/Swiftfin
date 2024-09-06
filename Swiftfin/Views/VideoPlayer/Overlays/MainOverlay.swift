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

        @ViewBuilder
        private var topBar: some View {
            Overlay.TopBarView()
                .edgePadding(.vertical)
                .padding(actualSafeArea)
                .background {
                    OpacityLinearGradient {
                        (0, 0.9)
                        (1, 0)
                    }
                    .foregroundStyle(.black)
                    .visible(playbackButtonType == .compact)
                }
                .visible(!isScrubbing && isPresentingOverlay)
        }

        @ViewBuilder
        private var bottomBar: some View {
            Overlay.BottomBarView()
                .edgePadding(.vertical)
                .padding(actualSafeArea)
                .background {
                    OpacityLinearGradient {
                        (0, 0)
                        (1, 0.9)
                    }
                    .foregroundStyle(.black)
                    .visible(isScrubbing || playbackButtonType == .compact)
                }
                .visible(isScrubbing || isPresentingOverlay)
        }

        var body: some View {
            ZStack {

                Color.black
                    .opacity(!isScrubbing && playbackButtonType == .large && isPresentingOverlay ? 0.5 : 0)
                    .allowsHitTesting(false)

                VStack {
                    topBar

                    Spacer()
                        .allowsHitTesting(false)

                    bottomBar
                }

                if playbackButtonType == .large {
                    Overlay.LargePlaybackButtons()
                        .visible(!isScrubbing && isPresentingOverlay)
                }
            }
            .animation(.linear(duration: 0.1), value: isScrubbing)
            .environmentObject(overlayTimer)
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

                withAnimation(.linear(duration: 0.3)) {
                    isPresentingOverlay = false
                }
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
