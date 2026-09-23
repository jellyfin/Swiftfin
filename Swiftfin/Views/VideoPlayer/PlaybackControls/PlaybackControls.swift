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
        @EnvironmentObject
        private var manager: MediaPlayerManager

        // TODO: do something with this value
        @State
        private var activeIsBuffering: Bool = false
        @State
        private var bottomContentFrame: CGRect = .zero

        private var isScrubbing: Bool {
            viewState.isScrubbing
        }

        // MARK: body

        var body: some View {
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
            .modifier(VideoPlayer.KeyCommandsModifier())
            .animation(.linear(duration: 0.1), value: isScrubbing)
            .animation(.bouncy(duration: 0.4), value: viewState.isPresentingSupplement)
            .animation(.bouncy(duration: 0.25), value: viewState.presentation)
            .onChange(of: manager.proxy?.isBuffering.value) {
                activeIsBuffering = manager.proxy?.isBuffering.value ?? false
            }
            .disabled(manager.error != nil)
        }
    }
}
