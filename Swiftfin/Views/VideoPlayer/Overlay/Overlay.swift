//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

// TODO: supplement transition animation fixes

extension VideoPlayer {

    struct Overlay: View {

        @Environment(\.isScrubbing)
        @Binding
        private var isScrubbing: Bool

        // since this view ignores safe area, it must
        // get safe area insets from parent views
        @Environment(\.safeAreaInsets)
        private var safeAreaInsets

        @EnvironmentObject
        private var manager: MediaPlayerManager

        @State
        private var effectiveSafeArea: EdgeInsets = .init(vertical: 0, horizontal: 50)
        @State
        private var isGestureLocked: Bool = false
        @State
        private var isPresentingOverlay: Bool = true
        @State
        private var progressViewFrame: CGRect = .zero
        @State
        private var selectedSupplement: AnyMediaPlayerSupplement?

        @StateObject
        private var jumpProgressObserver: JumpProgressObserver = .init()
        @StateObject
        private var overlayTimer: PokeIntervalTimer = .init()
        @StateObject
        private var toastProxy: ToastProxy = .init()

        private var isPresentingSupplement: Bool {
            selectedSupplement != nil
        }

        @ViewBuilder
        private var navigationBar: some View {
            NavigationBar()
                .isVisible(!isScrubbing && isPresentingOverlay)
        }

        @ViewBuilder
        private var bottomContent: some View {
            if !isPresentingSupplement {
                PlaybackProgress()
                    .isVisible(isScrubbing || isPresentingOverlay)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .trackingFrame($progressViewFrame)
            }

            // TODO: only here for current chapters implementation,
            //       replace with below
            if let selectedSupplement {
                SupplementTitleButton(supplement: selectedSupplement)
            }

//            HStack(spacing: 10) {
//                ForEach(manager.supplements.map(\.asAny)) { supplement in
//                    DrawerSectionButton(
//                        supplement: supplement
//                    )
//                }
//            }
//            .isVisible(!isScrubbing && isPresentingOverlay)
        }

        // MARK: body

        var body: some View {
            ZStack {

                // MARK: - Dark

                ZStack(alignment: .bottom) {

                    Color.black
                        .isVisible(opacity: 0.5, !isScrubbing && isPresentingOverlay)
                        .allowsHitTesting(false)

                    OpacityLinearGradient {
                        (0, 0)
                        (1, 0.5)
                    }
                    .foregroundStyle(.black)
                    .isVisible(isScrubbing)
                    .frame(height: progressViewFrame.height)
                }
                .animation(.linear(duration: 0.25), value: isPresentingOverlay)

                // MARK: - Gestures

                GestureLayer()

                // MARK: - Buttons and Supplements

                VStack {
                    navigationBar
                        .padding(.top, EdgeInsets.edgePadding / 2)
                        .padding(effectiveSafeArea)
                        .offset(y: isPresentingOverlay ? 0 : -20)

                    Spacer()
                        .allowsHitTesting(false)

                    VStack {
                        bottomContent
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(effectiveSafeArea)
                            .offset(y: isPresentingOverlay ? 0 : 20)

                        // TODO: changing supplement transition
                        if isPresentingSupplement, let selectedSupplement {
                            selectedSupplement.supplement
                                .videoPlayerBody()
                                .eraseToAnyView()
                                .frame(height: 150)
                                .id(selectedSupplement.id)
                                .transition(.opacity.animation(.linear(duration: 0.1)))
                                .environment(\.safeAreaInsets, effectiveSafeArea)
                        }

                        Color.clear
                            .frame(height: EdgeInsets.edgePadding)
                    }
                    .background {
                        if isPresentingOverlay {
                            EmptyHitTestView()
                        }
                    }
                }

                if !isPresentingSupplement {
                    PlaybackButtons()
                        .isVisible(!isScrubbing && isPresentingOverlay)
                        .transition(.opacity)
                }
            }
            .overlay(alignment: .top) {
                ToastView()
                    .edgePadding()
            }
            .modifier(VideoPlayer.KeyCommandsModifier())
            .animation(.linear(duration: 0.1), value: isScrubbing)
            .animation(.bouncy(duration: 0.4), value: isPresentingSupplement)
            .animation(.bouncy(duration: 0.25), value: isPresentingOverlay)
            .environment(\.isPresentingOverlay, $isPresentingOverlay)
            .environment(\.selectedMediaPlayerSupplement, $selectedSupplement)
            .environmentObject(jumpProgressObserver)
            .environmentObject(overlayTimer)
            .environmentObject(toastProxy)
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

                withAnimation(.linear(duration: 0.25)) {
                    isPresentingOverlay = false
                }
            }
            .onChange(of: selectedSupplement) { newValue in
                if newValue == nil {
                    overlayTimer.poke()
                } else {
                    overlayTimer.stop()
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
                            //                            channelType: .tv,
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
//            .environment(\.playbackSpeed, .constant(1.0))
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
