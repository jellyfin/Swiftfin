//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension VideoPlayer {

    struct PlaybackControls: View {

        typealias ViewState = VideoPlayer.ViewState

        // since this view ignores safe area, it must
        // get safe area insets from parent views
        @Environment(\.safeAreaInsets)
        private var safeAreaInsets

        @Environment(ViewState.self)
        private var viewState
        @Environment(MediaSession.self)
        private var mediaSession

        @State
        private var bottomContentFrame: CGRect = .zero

        @ScaledMetric(relativeTo: .subheadline)
        private var tabletopSubtitleSpacing: CGFloat = 24

        private var isScrubbing: Bool {
            viewState.isScrubbing
        }

        // MARK: body

        var body: some View {
            Group {
                if viewState.isTabletop {
                    tabletopBody
                } else {
                    overlayBody
                }
            }
            .modifier(VideoPlayer.KeyCommandsModifier())
            .animation(.linear(duration: 0.1), value: isScrubbing)
            .animation(.bouncy(duration: 0.4), value: viewState.isPresentingSupplement)
            .animation(.bouncy(duration: 0.25), value: viewState.presentation)
            .disabled(mediaSession.state == .error)
        }

        private var tabletopBody: some View {
            GeometryReader { geometry in
                ViewThatFits(in: .vertical) {
                    // Top-aligned so the toolbar stays put when a panel opens.
                    tabletopContent
                        .frame(maxHeight: .infinity, alignment: .top)

                    ScrollView(.vertical) {
                        tabletopContent
                            .padding(.bottom, viewState.isPresentingSupplement ? 0 : safeAreaInsets.bottom)
                    }
                    .scrollDisabled(viewState.isPresentingSupplement)
                }
                .padding(.leading, max(16, safeAreaInsets.leading))
                .padding(.trailing, max(16, safeAreaInsets.trailing))
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .foregroundStyle(.white)
            .background(.black)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(L10n.playback)
            .accessibilityIdentifier("tabletopPlaybackControls")
        }

        private var tabletopContent: some View {
            VStack(spacing: 8) {
                Toolbar()
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(minHeight: 50)
                    .isVisible(viewState.visibleElements.contains(.toolbar))
                    .enabled(viewState.visibleElements.contains(.toolbar))
                    // The title's episode subtitle extends below the toolbar row.
                    .padding(.bottom, tabletopSubtitleSpacing)
                    .onSizeChanged { size, _ in
                        // Includes the content's top padding.
                        viewState.tabletopToolbarHeight = size.height + 16
                    }

                Spacer(minLength: 0)

                PlaybackButtons()
                    .fixedSize(horizontal: false, vertical: true)
                    .isVisible(viewState.visibleElements.contains(.playbackButtons))
                    .enabled(viewState.visibleElements.contains(.playbackButtons))

                Spacer(minLength: 12)

                PlaybackProgress()
                    .fixedSize(horizontal: false, vertical: true)
                    .isVisible(viewState.isPresentingProgress)
                    .enabled(viewState.isPresentingProgress)
                    // Leaves room for the scrub preview without moving the slider.
                    .padding(.top, 12)
                    .padding(.bottom, tabletopSubtitleSpacing)

                if viewState.isGestureLocked {
                    Label(L10n.pressAndHoldToUnlock, systemImage: VideoPlayerActionButton.gestureLock.systemImage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else if viewState.overlayActions.isNotEmpty {
                    VideoPlayer.OverlayActions()
                        .fixedSize(horizontal: false, vertical: true)
                        .isVisible(viewState.isPresentingOverlayActions)
                        .enabled(viewState.isPresentingOverlayActions)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .fixedSize(horizontal: false, vertical: true)
            .disabled(viewState.isGestureLocked)
            .opacity(viewState.isGestureLocked ? 0.5 : 1)
        }

        private var overlayBody: some View {
            ZStack {
                VStack {
                    Toolbar()
                        .frame(height: 50)
                        .isVisible(viewState.visibleElements.contains(.toolbar))
                        .enabled(viewState.visibleElements.contains(.toolbar))
                        .padding(.top, safeAreaInsets.top)
                        .padding(.leading, safeAreaInsets.leading)
                        .padding(.trailing, safeAreaInsets.trailing)
                        .offset(y: viewState.isPresentingControls ? 0 : -20)

                    Spacer()
                        .allowsHitTesting(false)

                    PlaybackProgress()
                        .isVisible(viewState.isPresentingProgress)
                        .enabled(viewState.isPresentingProgress)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, safeAreaInsets.leading)
                        .padding(.trailing, safeAreaInsets.trailing)
                        .trackingFrame($bottomContentFrame)
                        .background {
                            if viewState.isPresentingProgress {
                                EmptyHitTestView()
                            }
                        }
                        .background(alignment: .top) {
                            Color.black
                                .mask(gradient: .linear) {
                                    (location: 0, opacity: 0)
                                    (location: 1, opacity: 0.5)
                                }
                                .isVisible(isScrubbing)
                                .frame(height: bottomContentFrame.height + 50 + EdgeInsets.edgePadding * 2)
                        }
                }

                PlaybackButtons()
                    .isVisible(viewState.visibleElements.contains(.playbackButtons))
                    .enabled(viewState.visibleElements.contains(.playbackButtons))
            }
        }
    }
}
