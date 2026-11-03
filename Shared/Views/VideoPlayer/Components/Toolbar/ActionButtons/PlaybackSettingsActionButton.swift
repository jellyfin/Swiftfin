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

extension VideoPlayer.PlaybackControls.Toolbar.ActionButtons {

    struct PlaybackSettings: View {

        @Environment(MediaSession.self)
        private var mediaSession

        static func isAvailable(for item: MediaPlayerItem?) -> Bool {
            guard let item else { return false }

            return item.baseItem.mediaType == .video
                || (item.baseItem.mediaSources?.count ?? 0) > 1
                || item.mediaSource.supportedBitrates.isNotEmpty
        }

        var body: some View {
            if let playbackItem = mediaSession.playbackItem {
                let bitrates = playbackItem.mediaSource.supportedBitrates
                let versions = playbackItem.baseItem.mediaSources ?? []
                let hasVersionSection = versions.count > 1
                let hasBitrateSection = bitrates.isNotEmpty

                Menu(
                    VideoPlayerActionButton.playbackSettings.displayTitle,
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

                                    var intent = playbackItem.resumingIntent(at: mediaSession.seconds)
                                    intent.configuration.selectMediaSource(id: newSource.id)
                                    mediaSession.playNewItem(intent: intent)
                                }
                            )
                        ) {
                            ForEach(versions) { version in
                                Text(version.displayTitle)
                                    .tag(version.id)
                            }
                        } label: {
                            Text(L10n.version)
                            Text(playbackItem.mediaSource.displayTitle)
                        }
                        .pickerStyle(.menu)
                    }

                    if hasBitrateSection {
                        Picker(
                            selection: Binding(
                                get: { playbackItem.configuration.requestedBitrate },
                                set: { newBitrate in
                                    guard newBitrate != playbackItem.configuration.requestedBitrate else { return }

                                    mediaSession.setBitrate(bitrate: newBitrate)
                                }
                            )
                        ) {
                            ForEach(bitrates, id: \.rawValue) { bitrate in
                                Text(bitrate.displayTitle)
                                    .tag(bitrate)
                            }
                        } label: {
                            Text(L10n.playbackQuality)
                            Text(playbackItem.configuration.requestedBitrate.displayTitle)
                        }
                        .pickerStyle(.menu)
                    }

                    if playbackItem.baseItem.mediaType == .video {
                        Picker(
                            selection: Binding(
                                get: { playbackItem.configuration.maxResolution },
                                set: { newResolution in
                                    guard newResolution != playbackItem.configuration.maxResolution else { return }

                                    mediaSession.setResolution(resolution: newResolution)
                                }
                            )
                        ) {
                            ForEach(PlaybackResolution.allCases, id: \.rawValue) { resolution in
                                Text(resolution.displayTitle)
                                    .tag(resolution)
                            }
                        } label: {
                            Text(L10n.resolution)
                            Text(playbackItem.configuration.maxResolution.displayTitle)
                        }
                        .pickerStyle(.menu)
                    }
                }
            }
        }
    }
}
