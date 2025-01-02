//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension VideoPlayer {

    struct MainOverlay: View {

        @Default(.VideoPlayer.Overlay.playbackButtonType)
        private var playbackButtonType

        @Environment(\.currentOverlayType)
        @Binding
        private var currentOverlayType
        @Environment(\.isPresentingOverlay)
        @Binding
        private var isPresentingOverlay
        @Environment(\.isScrubbing)
        @Binding
        private var isScrubbing: Bool
        @Environment(\.safeAreaInsets)
        private var safeAreaInsets

        @EnvironmentObject
        private var splitContentViewProxy: SplitContentViewProxy

        @StateObject
        private var overlayTimer: TimerProxy = .init()

        var body: some View {
            ZStack {
                VStack {
                    Overlay.TopBarView()
                        .if(UIDevice.hasNotch) { view in
                            view.padding(safeAreaInsets.mutating(\.trailing, with: 0))
                                .padding(.trailing, splitContentViewProxy.isPresentingSplitView ? 0 : safeAreaInsets.trailing)
                        }
                        .if(UIDevice.isPad) { view in
                            view.padding(.top)
                                .padding(.horizontal)
                        }
                        .background {
                            LinearGradient(
                                stops: [
                                    .init(color: .black.opacity(0.9), location: 0),
                                    .init(color: .clear, location: 1),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .visible(playbackButtonType == .compact)
                        }
                        .visible(!isScrubbing && isPresentingOverlay)

                    Spacer()
                        .allowsHitTesting(false)

                    Overlay.BottomBarView()
                        .if(UIDevice.hasNotch) { view in
                            view.padding(safeAreaInsets.mutating(\.trailing, with: 0))
                                .padding(.trailing, splitContentViewProxy.isPresentingSplitView ? 0 : safeAreaInsets.trailing)
                        }
                        .if(UIDevice.isPad) { view in
                            view.padding(.bottom)
                                .padding(.horizontal)
                        }
                        .background {
                            LinearGradient(
                                stops: [
                                    .init(color: .clear, location: 0),
                                    .init(color: .black.opacity(0.5), location: 0.5),
                                    .init(color: .black.opacity(0.5), location: 1),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .visible(isScrubbing || playbackButtonType == .compact)
                        }
                        .background {
                            Color.clear
                                .allowsHitTesting(true)
                                .contentShape(Rectangle())
                                .allowsHitTesting(true)
                        }
                        .visible(isScrubbing || isPresentingOverlay)
                }

                if playbackButtonType == .large {
                    Overlay.LargePlaybackButtons()
                        .visible(!isScrubbing && isPresentingOverlay)
                }
            }
            .environmentObject(overlayTimer)
            .background {
                Color.black
                    .opacity(!isScrubbing && playbackButtonType == .large && isPresentingOverlay ? 0.5 : 0)
                    .allowsHitTesting(false)
            }
            .animation(.linear(duration: 0.1), value: isScrubbing)
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
        }
    }
}
