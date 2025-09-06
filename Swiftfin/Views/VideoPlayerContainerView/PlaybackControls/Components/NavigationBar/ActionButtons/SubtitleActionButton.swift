//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer.PlaybackControls.NavigationBar.ActionButtons {

    struct Subtitles: View {

        @Environment(\.isInMenu)
        private var isInMenu

        @EnvironmentObject
        private var manager: MediaPlayerManager

        @State
        private var selectedSubtitleStreamIndex: Int?

        private var systemImage: String {
            if selectedSubtitleStreamIndex == nil {
                "captions.bubble"
            } else {
                "captions.bubble.fill"
            }
        }

        @ViewBuilder
        private func content(playbackItem: MediaPlayerItem) -> some View {
            ForEach(playbackItem.subtitleStreams.prepending(.none), id: \.index) { stream in
                Button {
                    playbackItem.selectedSubtitleStreamIndex = stream.index ?? -1
                } label: {
                    if selectedSubtitleStreamIndex == stream.index {
                        Label(stream.displayTitle ?? L10n.unknown, systemImage: "checkmark")
                    } else {
                        Text(stream.displayTitle ?? L10n.unknown)
                    }
                }
            }
        }

        var body: some View {
            if let playbackItem = manager.playbackItem {
                Menu(
                    L10n.subtitles,
                    systemImage: systemImage
                ) {
                    if isInMenu {
                        content(playbackItem: playbackItem)
                    } else {
                        Section(L10n.subtitles) {
                            content(playbackItem: playbackItem)
                        }
                    }
                }
                .videoPlayerActionButtonTransition()
                .assign(playbackItem.$selectedSubtitleStreamIndex, to: $selectedSubtitleStreamIndex)
            }
        }
    }
}
