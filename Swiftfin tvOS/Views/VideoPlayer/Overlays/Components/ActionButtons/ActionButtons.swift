//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension VideoPlayer.Overlay.NavigationBar {

    struct ActionButtons: View {

        @Default(.VideoPlayer.barActionButtons)
        private var barActionButtons
        @Default(.VideoPlayer.menuActionButtons)
        private var menuActionButtons

        @EnvironmentObject
        private var overlayTimer: PokeIntervalTimer

        @ViewBuilder
        private func view(for button: VideoPlayerActionButton) -> some View {
            switch button {
            case .aspectFill:
                AspectFill()
            default: EmptyView()
            }

//            switch button {
//            case .aspectFill:
//                AspectFill()
//            case .audio:
//                if manager.playbackItem?.audioStreams.isNotEmpty == true {
//                    Audio()
//                }
//            case .autoPlay:
//                if manager.queue != nil {
//                    AutoPlay()
//                }
//            case .chapters:
//                if manager.item.fullChapterInfo.isNotEmpty {
//                    ChaptersButton()
//                }
//            case .playbackSpeed:
//                if !manager.item.isLiveStream {
//                    PlaybackRateMenu()
//                }
//            case .playNextItem:
//                if manager.queue != nil {
//                    PlayNextItem()
//                }
//            case .playPreviousItem:
//                if manager.queue != nil {
//                    PlayPreviousItem()
//                }
//            case .subtitles:
//                if manager.playbackItem?.subtitleStreams.isNotEmpty == true {
//                    Subtitles()
//                }
//            }
        }

        @ViewBuilder
        private var menuButtons: some View {
            Menu(
                "Menu",
                systemImage: "ellipsis.circle"
            ) {
                ForEach(menuActionButtons) { actionButton in
                    view(for: actionButton)
                }
            }
        }

        var body: some View {
            HStack(spacing: 0) {
                ForEach(
                    VideoPlayerActionButton.allCases,
                    content: view(for:)
                )

//                ForEach(barActionButtons) { actionButton in
//                    view(for: actionButton)
//                }
//
//                if menuActionButtons.isNotEmpty {
//                    menuButtons
//                }
            }
        }
    }
}
