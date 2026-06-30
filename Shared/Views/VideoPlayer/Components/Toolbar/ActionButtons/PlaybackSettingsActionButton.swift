//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

// TODO: compatibility picker
// TODO: don't present for offline/live items
//       - value on media player item

extension VideoPlayer.PlaybackControls.Toolbar.ActionButtons {

    struct PlaybackSettings: View {

        @EnvironmentObject
        private var manager: MediaPlayerManager

        private func makeProvider(for mediaSource: MediaSourceInfo, playbackItem: MediaPlayerItem) -> MediaPlayerItemProvider {
            var adjustedBaseItem = playbackItem.baseItem
            adjustedBaseItem.userData?.playbackPositionTicks = manager.seconds.ticks
            let requestedBitrate = playbackItem.requestedBitrate

            return MediaPlayerItemProvider(item: adjustedBaseItem) { baseItem in
                try await MediaPlayerItem.build(
                    for: baseItem,
                    mediaSource: mediaSource,
                    requestedBitrate: requestedBitrate
                )
            }
        }

        var body: some View {
            if let playbackItem = manager.playbackItem {
                let bitrates = playbackItem.mediaSource.supportedBitrates
                let versions = playbackItem.baseItem.mediaSources ?? []
                let hasVersionSection = versions.count > 1
                let hasBitrateSection = bitrates.isNotEmpty
                let hasMultipleSections = hasVersionSection && hasBitrateSection
                let menuTitle: String = {
                    if hasMultipleSections {
                        VideoPlayerActionButton.playbackSettings.displayTitle
                    } else if hasVersionSection {
                        L10n.version
                    } else {
                        L10n.playbackQuality
                    }
                }()

                Menu(
                    menuTitle,
                    systemImage: VideoPlayerActionButton.playbackSettings.systemImage
                ) {
                    if hasVersionSection {
                        Picker(
                            selection: Binding(
                                get: { playbackItem.mediaSource.id },
                                set: { newID in
                                    guard let newID,
                                          newID != playbackItem.mediaSource.id,
                                          let newSource = versions.first(where: { $0.id == newID })
                                    else { return }

                                    manager.playNewItem(provider: makeProvider(for: newSource, playbackItem: playbackItem))
                                }
                            )
                        ) {
                            ForEach(versions, id: \.hashValue) { version in
                                Text(version.displayTitle)
                                    .tag(version.id)
                            }
                        } label: {
                            Text(L10n.version)
                            Text(playbackItem.mediaSource.displayTitle)
                        }
                        .if(hasMultipleSections) { picker in
                            picker.pickerStyle(.menu)
                        }
                    }

                    if hasBitrateSection {
                        Picker(
                            selection: Binding(
                                get: { playbackItem.requestedBitrate },
                                set: { newBitrate in
                                    guard newBitrate != playbackItem.requestedBitrate else { return }
                                    manager.setBitrate(bitrate: newBitrate)
                                }
                            )
                        ) {
                            ForEach(bitrates, id: \.rawValue) { bitrate in
                                Text(bitrate.displayTitle)
                                    .tag(bitrate)
                            }
                        } label: {
                            Text(L10n.playbackQuality)
                            Text(playbackItem.requestedBitrate.displayTitle)
                        }
                        .if(hasMultipleSections) { picker in
                            picker.pickerStyle(.menu)
                        }
                    }
                }
            }
        }
    }
}
