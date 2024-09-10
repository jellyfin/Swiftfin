//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI
import VLCUI

extension VideoPlayer.Overlay {

    struct BottomBarView: View {

        @Default(.VideoPlayer.Overlay.chapterSlider)
        private var chapterSlider
        @Default(.VideoPlayer.Overlay.playbackButtonType)
        private var playbackButtonType
        @Default(.VideoPlayer.Overlay.sliderType)
        private var sliderType

        @Environment(\.isPresentingOverlay)
        @Binding
        private var isPresentingOverlay: Bool
        @Environment(\.isScrubbing)
        @Binding
        private var isScrubbing: Bool

//        @Environment(\.isPresentingDrawer)
//        @Binding
        @State
        private var isPresentingDrawer: Bool = false

        @EnvironmentObject
        private var overlayTimer: DelayIntervalTimer
        @EnvironmentObject
        private var manager: MediaPlayerManager

        @EnvironmentObject
        private var scrubbedProgress: ProgressBox

        @State
        private var currentChapter: ChapterInfo.FullInfo?
        @State
        private var pulse = false

        @ViewBuilder
        private var capsuleSlider: some View {
            CapsuleSlider(progress: $scrubbedProgress.progress)
                .isEditing(_isScrubbing.wrappedValue)
                .bottomContent {
                    SplitTimeStamp()
                        .padding(5)
                }
                .leadingContent {
                    if playbackButtonType == .compact {
                        SmallPlaybackButtons()
                            .padding(.trailing)
                            .disabled(isScrubbing)
                    }
                }
                .frame(height: 50)
        }

        @ViewBuilder
        private var thumbSlider: some View {
            ThumbSlider(progress: $scrubbedProgress.progress)
                .isEditing(_isScrubbing.wrappedValue)
                .bottomContent {
                    SplitTimeStamp()
                        .padding(5)
                }
                .leadingContent {
                    if playbackButtonType == .compact {
                        SmallPlaybackButtons()
                            .padding(.trailing)
                            .disabled(isScrubbing)
                    }
                }
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                if !isPresentingDrawer {
                    Group {
                        switch sliderType {
                        case .capsule: capsuleSlider
                        case .thumb: thumbSlider
                        }
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                DrawerSectionView(selectedDrawerSection: .mock(-1))
                    .environment(\.isPresentingDrawer, $isPresentingDrawer)

                if isPresentingDrawer {
                    Color.red
                        .frame(height: 100)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.bouncy(duration: 0.4), value: isPresentingDrawer)
            .disabled(manager.state == .loadingItem)
            .onChange(of: isPresentingDrawer) { newValue in
                print("drawer:", newValue)
            }
//            .onChange(of: manager.state) { newValue in
//                pulse = newValue == .loadingItem
//            }
        }
    }
}
