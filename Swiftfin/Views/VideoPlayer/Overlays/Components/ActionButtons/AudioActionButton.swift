//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension VideoPlayer.Overlay.ActionButtons {

    struct Audio: View {

        @EnvironmentObject
        private var manager: MediaPlayerManager

        private var systemImage: String {
            if manager.playbackItem?.selectedAudioStreamIndex == nil {
                "speaker.wave.2"
            } else {
                "speaker.wave.2.fill"
            }
        }

        var body: some View {
            if let playbackItem = manager.playbackItem {
                Menu(
                    L10n.audio,
                    systemImage: systemImage
                ) {
                    Section(L10n.audio) {
                        ForEach(playbackItem.audioStreams, id: \.index) { stream in
                            Button {
                                playbackItem.selectedAudioStreamIndex = stream.index ?? -1
                            } label: {
                                if playbackItem.selectedAudioStreamIndex == stream.index {
                                    Label(stream.displayTitle ?? L10n.unknown, systemImage: "checkmark")
                                } else {
                                    Text(stream.displayTitle ?? L10n.unknown)
                                }
                            }
                        }
                    }
                }
                .transition(.opacity.combined(with: .scale).animation(.snappy))
                .id(systemImage)
            }
        }
    }
}
