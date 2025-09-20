//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer.PlaybackControls.NavigationBar.ActionButtons {

    struct Audio: View {

        @Environment(\.isInMenu)
        private var isInMenu

        @EnvironmentObject
        private var manager: MediaPlayerManager

        @State
        private var selectedAudioStreamIndex: Int?

        private var systemImage: String {
            if selectedAudioStreamIndex == nil {
                "speaker.wave.2"
            } else {
                "speaker.wave.2.fill"
            }
        }

        @ViewBuilder
        private func content(playbackItem: MediaPlayerItem) -> some View {
            ForEach(playbackItem.audioStreams, id: \.index) { stream in
                Button {
                    playbackItem.selectedAudioStreamIndex = stream.index ?? -1
                } label: {
                    if selectedAudioStreamIndex == stream.index {
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
                    L10n.audio,
                    systemImage: systemImage
                ) {
                    if isInMenu {
                        content(playbackItem: playbackItem)
                    } else {
                        Section(L10n.audio) {
                            content(playbackItem: playbackItem)
                        }
                    }
                }
                .videoPlayerActionButtonTransition()
                .assign(playbackItem.$selectedAudioStreamIndex, to: $selectedAudioStreamIndex)
            }
        }
    }
}
