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

    struct Subtitles: View {

        @EnvironmentObject
        private var manager: MediaPlayerManager

        private var systemImage: String {
            if manager.playbackItem?.selectedSubtitleStreamIndex == nil {
                "captions.bubble"
            } else {
                "captions.bubble.fill"
            }
        }

        var body: some View {
            if let playbackItem = manager.playbackItem {
                Menu(
                    L10n.subtitles,
                    systemImage: systemImage
                ) {
                    Section(L10n.subtitles) {
                        ForEach(playbackItem.subtitleStreams.prepending(.none), id: \.index) { stream in
                            Button {
                                playbackItem.selectedSubtitleStreamIndex = stream.index ?? -1
                            } label: {
                                if playbackItem.selectedSubtitleStreamIndex == stream.index {
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
