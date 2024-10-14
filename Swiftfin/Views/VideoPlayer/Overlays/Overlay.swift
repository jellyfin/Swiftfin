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

    struct Overlay: View {

        @Default(.VideoPlayer.Overlay.playbackButtonType)
        private var playbackButtonType

        @Environment(\.isPresentingOverlay)
        @Binding
        private var isPresentingOverlay
        @Environment(\.isScrubbing)
        @Binding
        private var isScrubbing: Bool

        // since this view ignores safe area, it must
        // get safe area insets from parent views
        @Environment(\.safeAreaInsets)
        @Binding
        private var safeAreaInsets

        @EnvironmentObject
        private var manager: MediaPlayerManager

        @State
        private var effectiveSafeArea: EdgeInsets = .zero

        @State
        private var selectedSupplement: AnyMediaPlayerSupplement?

        @StateObject
        private var overlayTimer: PokeIntervalTimer = .init(defaultInterval: 5)

        private var isPresentingDrawer: Bool {
            selectedSupplement != nil
        }

        @ViewBuilder
        private var topBar: some View {
            Overlay.TopBarView()
                .edgePadding(.vertical)
                .padding(effectiveSafeArea)
                .background {
                    OpacityLinearGradient {
                        (0, 0.9)
                        (1, 0)
                    }
                    .foregroundStyle(.black)
                    .isVisible(playbackButtonType == .compact)
                }
                .isVisible(!isScrubbing && isPresentingOverlay)
                .offset(y: isPresentingOverlay ? 0 : -20)
                .animation(.bouncy, value: isPresentingOverlay)
        }

        @ViewBuilder
        private var bottomBar: some View {
            Overlay.BottomBarView()
                .padding(effectiveSafeArea)
                .background {
                    OpacityLinearGradient {
                        (0, 0)
                        (1, 0.9)
                    }
                    .foregroundStyle(.black)
                    .isVisible(isScrubbing || playbackButtonType == .compact)
                }
                .isVisible(isScrubbing || isPresentingOverlay)
                .offset(y: isPresentingOverlay ? 0 : 20)
                .animation(.bouncy, value: isPresentingOverlay)
                .transition(.move(edge: .top).combined(with: .opacity))
        }

        @ViewBuilder
        private var drawerTitleSection: some View {
            HStack(spacing: 10) {
                ForEach(manager.supplements.map { AnyMediaPlayerSupplement(supplement: $0) }) { supplement in
                    DrawerSectionButton(
                        supplement: supplement
                    )
                }
            }
        }

        var body: some View {
            ZStack {

                Color.black
                    .opacity(!isScrubbing && playbackButtonType == .large && isPresentingOverlay ? 0.5 : 0)
                    .allowsHitTesting(false)

                GestureView()
                    .onTap(samePointPadding: 10, samePointTimeout: 0.7) { _, _ in
                        print("here")
                        if isPresentingDrawer {
                            selectedSupplement = nil
                        } else {
                            isPresentingOverlay.toggle()
                        }
                    }

                VStack {
                    topBar

                    Spacer()
                        .allowsHitTesting(false)

                    if !isPresentingDrawer {
                        bottomBar
                    }

                    drawerTitleSection
                        .padding(effectiveSafeArea)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .isVisible(!isScrubbing && isPresentingOverlay)
                        .offset(y: isPresentingOverlay ? 0 : 20)
                        .animation(.bouncy, value: isPresentingOverlay)

                    // TODO: transition
                    if isPresentingDrawer, let selectedSupplement {
                        selectedSupplement.supplement
                            .videoPlayerBody()
                            .eraseToAnyView()
                            .frame(height: 150)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .environment(\.safeAreaInsets, .constant(effectiveSafeArea))
                    }

                    Color.clear
                        .frame(height: EdgeInsets.edgePadding)
                        .allowsHitTesting(false)
                }

                if playbackButtonType == .large, !isPresentingDrawer {
                    Overlay.LargePlaybackButtons()
                        .isVisible(!isScrubbing && isPresentingOverlay)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.linear(duration: 0.1), value: isScrubbing)
            .animation(.bouncy, value: isPresentingDrawer)
            .environment(\.selectedMediaPlayerSupplement, $selectedSupplement)
            .environmentObject(overlayTimer)
            .onChange(of: selectedSupplement) { newValue in
                if newValue == nil {
                    overlayTimer.poke()
                } else {
                    overlayTimer.stop()
                }
            }
            .onChange(of: isPresentingOverlay) { newValue in
                guard newValue, !isScrubbing else { return }
                overlayTimer.poke()
            }
            .onChange(of: isScrubbing) { newValue in
                if newValue {
                    overlayTimer.stop()
                } else {
                    overlayTimer.poke()
                }
            }
            .onReceive(overlayTimer.hasFired) { _ in
                guard !isScrubbing else { return }

                withAnimation(.linear(duration: 0.3)) {
                    isPresentingOverlay = false
                }
            }
            .onSizeChanged { newSize in
                if newSize.isPortrait {
                    effectiveSafeArea = .init(
                        vertical: min(safeAreaInsets.top, safeAreaInsets.bottom),
                        horizontal: 0
                    )
                } else {
                    effectiveSafeArea = .init(
                        vertical: 0,
                        horizontal: min(safeAreaInsets.leading, safeAreaInsets.trailing)
                    )
                }
            }
        }
    }
}

import VLCUI

struct VideoPlayer_Overlay_Previews: PreviewProvider {

    static var previews: some View {
        VideoPlayer.Overlay()
            .environmentObject(
                MediaPlayerManager(
                    playbackItem: .init(
                        baseItem: .init(
                            indexNumber: 1,
                            name: "The Bear",
                            parentIndexNumber: 1,
                            runTimeTicks: 10_000_000_000,
                            type: .episode
                        ),
                        mediaSource: .init(),
                        playSessionID: "",
                        url: URL(string: "/")!
                    )
                )
            )
            .environmentObject(VLCVideoPlayer.Proxy())
            .environment(\.isScrubbing, .mock(false))
            .environment(\.isAspectFilled, .mock(false))
            .environment(\.isPresentingOverlay, .constant(true))
            .environment(\.playbackSpeed, .constant(1.0))
            .environment(\.selectedMediaPlayerSupplement, .mock(nil))
            .previewInterfaceOrientation(.landscapeLeft)
            .preferredColorScheme(.dark)
    }
}

extension Binding {

    static func mock(_ value: Value) -> Self {
        var value = value
        return Binding(
            get: { value },
            set: { value = $0 }
        )
    }
}
