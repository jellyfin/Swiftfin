//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

extension ItemActionButtons {

    struct Playback: View {

        @EnvironmentObject
        private var provider: ItemContentGroupProvider

        @Default(.VideoPlayer.Playback.appMaximumBitrate)
        private var appMaximumBitrate

        @ViewContextContains(.isInMenu)
        private var isInMenu

        private var mediaSources: [MediaSourceInfo] {
            provider.mediaPlayerItemProvider?.item.mediaSources ?? []
        }

        // TODO: Fix External Audio Tracks & Re-Enable
        private var audioStreams: [MediaStream] {
            provider.mediaPlayerItemProvider?.mediaSource?.audioStreams?.filter { $0.isExternal != true } ?? []
        }

        private var subtitleStreams: [MediaStream] {
            provider.mediaPlayerItemProvider?.mediaSource?.subtitleStreams ?? []
        }

        private var supportedBitrates: [PlaybackBitrate] {
            provider.mediaPlayerItemProvider?.mediaSource?.supportedBitrates ?? []
        }

        private var audioStreamSelection: Binding<Int?> {
            Binding(
                get: {
                    provider.mediaPlayerItemProvider?.audioStreamIndex
                        ?? provider.mediaPlayerItemProvider?.mediaSource?.defaultAudioStreamIndex
                        ?? audioStreams.first?.index
                },
                set: { provider.select(.audioStreamIndex($0)) }
            )
        }

        private var subtitleStreamSelection: Binding<Int?> {
            Binding(
                get: {
                    provider.mediaPlayerItemProvider?.subtitleStreamIndex
                        ?? provider.mediaPlayerItemProvider?.mediaSource?.defaultSubtitleStreamIndex
                        ?? -1
                },
                set: { provider.select(.subtitleStreamIndex($0)) }
            )
        }

        @ViewBuilder
        private var versionPicker: some View {
            Picker(
                selection: Binding(
                    get: { provider.mediaPlayerItemProvider?.mediaSource },
                    set: { provider.select(.mediaSource($0)) }
                )
            ) {
                ForEach(mediaSources) { mediaSource in
                    Text(mediaSource.displayTitle)
                        .tag(mediaSource as MediaSourceInfo?)
                }
            } label: {
                Text(L10n.version)

                Text(provider.mediaPlayerItemProvider?.mediaSource?.displayTitle ?? L10n.none)
            }
            .pickerStyle(.menu)
        }

        @ViewBuilder
        private var qualityPicker: some View {
            Picker(
                selection: Binding(
                    get: { provider.mediaPlayerItemProvider?.requestedBitrate ?? appMaximumBitrate },
                    set: { provider.select(.bitrate($0)) }
                )
            ) {
                ForEach(supportedBitrates, id: \.rawValue) { bitrate in
                    Text(bitrate.displayTitle)
                        .tag(bitrate)
                }
            } label: {
                Text(L10n.playbackQuality)
                Text(provider.mediaPlayerItemProvider?.requestedBitrate.displayTitle)
            }
            .pickerStyle(.menu)
        }

        @ViewBuilder
        private func trackPicker(
            _ title: String,
            streams: [MediaStream],
            selection: Binding<Int?>
        ) -> some View {
            Picker(selection: selection) {
                ForEach(streams, id: \.index) { stream in
                    Text(stream.displayTitle ?? L10n.unknown)
                        .tag(stream.index as Int?)
                }
            } label: {
                Text(title)

                if let selectedStream = streams.first(where: { $0.index == selection.wrappedValue }) {
                    Text(selectedStream.displayTitle ?? L10n.unknown)
                }
            }
            .pickerStyle(.menu)
        }

        var body: some View {
            Menu(
                ItemActionButton.playback.displayTitle,
                systemImage: ItemActionButton.playback.systemImage
            ) {
                Section(L10n.source) {
                    if mediaSources.count > 1 {
                        versionPicker
                    }
                    qualityPicker
                }

                if audioStreams.isNotEmpty || subtitleStreams.isNotEmpty {
                    Section(L10n.tracks) {
                        if audioStreams.isNotEmpty {
                            trackPicker(
                                L10n.audio,
                                streams: audioStreams,
                                selection: audioStreamSelection
                            )
                        }

                        if subtitleStreams.isNotEmpty {
                            trackPicker(
                                L10n.subtitles,
                                streams: subtitleStreams.prepending(.none),
                                selection: subtitleStreamSelection
                            )
                        }
                    }
                }
            }
            .if(!isInMenu && UIDevice.isTV) { menu in
                menu.menuStyle(.button)
            }
        }
    }
}
