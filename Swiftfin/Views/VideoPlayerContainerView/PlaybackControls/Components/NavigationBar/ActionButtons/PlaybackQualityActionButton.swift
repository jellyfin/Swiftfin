//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: compatibility picker
// TODO: auto test setting
// TODO: change to general playback settings?
//       - versions
// TODO: have queue consider value to carry setting
// TODO: reuse-provider instead of making a new one?
// TODO: don't present for offline/live items
//       - value on media player item
// TODO: filter to sensible subset

extension VideoPlayer.PlaybackControls.NavigationBar.ActionButtons {

    struct PlaybackQuality: View {

        @Environment(\.isInMenu)
        private var isInMenu

        @EnvironmentObject
        private var manager: MediaPlayerManager

        private func makeProvider(with bitrate: PlaybackBitrate, for playbackItem: MediaPlayerItem) -> MediaPlayerItemProvider {
            var adjustedBaseItem = playbackItem.baseItem
            adjustedBaseItem.userData?.playbackPositionTicks = manager.seconds.ticks
            let mediaSource = playbackItem.mediaSource

            return MediaPlayerItemProvider(
                item: adjustedBaseItem,
                function: { baseItem in
                    try await MediaPlayerItem.build(
                        for: baseItem,
                        mediaSource: mediaSource,
                        requestedBitrate: bitrate
                    )
                }
            )
        }

        // TODO: transition to Picker
        //       - need local State value
        @ViewBuilder
        private func content(playbackItem: MediaPlayerItem) -> some View {
            ForEach(PlaybackBitrate.allCases, id: \.rawValue) { bitrate in
                Button {
                    guard playbackItem.requestedBitrate != bitrate else { return }
                    let provider = makeProvider(with: bitrate, for: playbackItem)
                    manager.playNewItem(provider: provider)
                } label: {
                    if playbackItem.requestedBitrate == bitrate {
                        Label(bitrate.displayTitle, systemImage: "checkmark")
                    } else {
                        Text(bitrate.displayTitle)
                    }
                }
            }
        }

        var body: some View {
            if let playbackItem = manager.playbackItem {
                Menu(
                    L10n.playbackQuality,
                    systemImage: ""
//                    systemImage: VideoPlayerActionButton.playbackQuality.systemImage
                ) {
                    if isInMenu {
                        content(playbackItem: playbackItem)
                    } else {
                        Section(L10n.playbackQuality) {
                            content(playbackItem: playbackItem)
                        }
                    }
                }
            }
        }
    }
}
