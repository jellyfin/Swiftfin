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
                VideoPlayerActionButton.subtitles.secondarySystemImage
            } else {
                VideoPlayerActionButton.subtitles.systemImage
            }
        }

        @ViewBuilder
        private func content(playbackItem: MediaPlayerItem) -> some View {
            Picker(L10n.subtitles, selection: $selectedSubtitleStreamIndex) {
                ForEach(playbackItem.subtitleStreams.prepending(.none), id: \.index) { stream in
                    Text(stream.displayTitle ?? L10n.unknown)
                        .tag(stream.index as Int?)
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
                .backport
                .onChange(of: selectedSubtitleStreamIndex) { _, newValue in
                    playbackItem.selectedSubtitleStreamIndex = newValue
                }
            }
        }
    }
}
