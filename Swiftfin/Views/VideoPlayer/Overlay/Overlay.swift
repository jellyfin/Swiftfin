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
// TODO: have overlay show after presentation/rotation
// TODO: error state

extension VideoPlayer {

    struct Overlay: View {

        @Environment(\.horizontalSizeClass)
        private var horizontalSizeClass

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
        private var bottomContentFrame: CGRect = .zero
        @State
        private var isGestureLocked: Bool = false
        @State
        private var isPresentingOverlay: Bool = true
        @State
        private var selectedSupplement: AnyMediaPlayerSupplement?

        @StateObject
        private var jumpProgressObserver: JumpProgressObserver = .init()
        @StateObject
        private var overlayTimer: PokeIntervalTimer = .init()

        private var isPresentingSupplement: Bool {
            selectedSupplement != nil
        }

        @ViewBuilder
        private var navigationBar: some View {
            NavigationBar()
                .isVisible(!isScrubbing && isPresentingOverlay)
        }

        // TODO: have progressViewFrame be the entire bottom content
        @ViewBuilder
        private var bottomContent: some View {
            if !isPresentingSupplement {
                PlaybackProgress()
                    .isVisible(isScrubbing || isPresentingOverlay)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            HStack(spacing: 10) {
                ForEach(manager.supplements.map(\.asAny)) { supplement in
                    SupplementTitleButton(supplement: supplement)
                }

                if let queue = manager.queue {
                    SupplementTitleButton(supplement: queue.asAny)
                }
            }
            .frame(minHeight: 30)
            .isVisible(!isScrubbing && isPresentingOverlay)
            .edgePadding(.leading)
        }

        // MARK: body

        var body: some View {
            ZStack {

                // MARK: - Dark

                ZStack(alignment: .bottom) {

                    Color.black
                        .isVisible(opacity: 0.5, !isScrubbing && isPresentingOverlay)
                        .allowsHitTesting(false)

                    Color.black
                        .maskLinearGradient {
                            (location: 0, opacity: 0)
                            (location: 1, opacity: 0.5)
                        }
                        .isVisible(isScrubbing)
                        .frame(height: bottomContentFrame.height)
                }
                .animation(.linear(duration: 0.25), value: isPresentingOverlay)

                // MARK: - Gestures

                GestureLayer()

                // MARK: - Buttons and Supplements

                VStack {
                    navigationBar
                        .padding(.top, safeAreaInsets.top)
                        .padding(.leading, safeAreaInsets.leading)
                        .padding(.trailing, safeAreaInsets.trailing)
                        .offset(y: isPresentingOverlay ? 0 : -20)

                    Spacer()
                        .allowsHitTesting(false)

                    // Only apply horizontal safe area to bottom content, have
                    // supplement bodies internally respond to safe area
                    VStack {
                        bottomContent
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .offset(y: isPresentingOverlay ? 0 : 20)
                            .trackingFrame($bottomContentFrame)
                            .padding(.leading, safeAreaInsets.leading)
                            .padding(.trailing, safeAreaInsets.trailing)

                        // TODO: changing supplement transition
                        if isPresentingSupplement, let selectedSupplement {
                            selectedSupplement.supplement
                                .videoPlayerBody()
                                .eraseToAnyView()
                                .frame(height: 150, alignment: .topLeading)
//                                .frame(height: horizontalSizeClass == .compact ? 400 : 150, alignment: .topLeading)
                                .id(selectedSupplement.id)
                                .transition(.opacity.animation(.linear(duration: 0.1)))
                        }
                    }
                    .background {
                        if isPresentingOverlay {
                            EmptyHitTestView()
                        }
                    }
                    .padding(.bottom, safeAreaInsets.bottom)
                }

                if !isPresentingSupplement {
                    PlaybackButtons()
                        .isVisible(!isScrubbing && isPresentingOverlay)
                        .transition(.opacity)
                }
            }
            .modifier(VideoPlayer.KeyCommandsModifier())
            .animation(.linear(duration: 0.1), value: isScrubbing)
            .animation(.bouncy(duration: 0.4), value: isPresentingSupplement)
            .animation(.bouncy(duration: 0.25), value: isPresentingOverlay)
            .environment(\.isPresentingOverlay, $isPresentingOverlay)
            .environment(\.selectedMediaPlayerSupplement, $selectedSupplement)
            .environmentObject(jumpProgressObserver)
            .environmentObject(overlayTimer)
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
        }
    }
}
