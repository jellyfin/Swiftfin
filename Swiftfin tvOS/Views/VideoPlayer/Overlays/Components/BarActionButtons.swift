//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: add subtitles button

extension VideoPlayer.Overlay {

    struct BarActionButtons: View {

        @Environment(\.currentOverlayType)
        @Binding
        private var currentOverlayType

        @EnvironmentObject
        private var viewModel: VideoPlayerViewModel

        @ViewBuilder
        private var autoPlayButton: some View {
            if viewModel.item.type == .episode {
                ActionButtons.AutoPlay()
            }
        }

        @ViewBuilder
        private var chaptersButton: some View {
            if viewModel.chapters.isNotEmpty {
                ActionButtons.Chapters()
            }
        }

        @ViewBuilder
        private var playNextItemButton: some View {
            if viewModel.item.type == .episode {
                ActionButtons.PlayNextItem()
            }
        }

        @ViewBuilder
        private var playPreviousItemButton: some View {
            if viewModel.item.type == .episode {
                ActionButtons.PlayPreviousItem()
            }
        }

        @ViewBuilder
        private var menuItemButton: some View {
            SFSymbolButton(
                systemName: "ellipsis.circle",
                systemNameFocused: "ellipsis.circle.fill"
            )
            .onSelect {
                currentOverlayType = .smallMenu
            }
            .frame(maxWidth: 30, maxHeight: 30)
        }

        var body: some View {
            HStack {
                playPreviousItemButton

                playNextItemButton

                autoPlayButton

                chaptersButton

                menuItemButton
            }
        }
    }
}
