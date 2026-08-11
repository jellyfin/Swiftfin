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

extension MediaPlayerItemProvider {

    var audioStreams: [MediaStream] {
        mediaSource?.audioStreams?.filter { $0.isExternal != true } ?? []
    }

    var subtitleStreams: [MediaStream] {
        mediaSource?.subtitleStreams ?? []
    }

    var supportedBitrates: [PlaybackBitrate] {
        mediaSource?.supportedBitrates ?? []
    }

    var hasPlaybackOptions: Bool {
        (item.mediaSources?.count ?? 0) > 1
            || audioStreams.count > 1
            || subtitleStreams.isNotEmpty
            || supportedBitrates.count > 1
    }
}

extension ItemActionButtons {

    struct Playback: View {

        @Default(.VideoPlayer.Playback.appMaximumBitrate)
        private var appMaximumBitrate

        @ViewContextContains(.isInMenu)
        private var isInMenu

        @EnvironmentObject
        private var provider: ItemContentGroupProvider

        private var itemProvider: MediaPlayerItemProvider? {
            provider.mediaPlayerItemProvider
        }

        private var mediaSources: [MediaSourceInfo] {
            itemProvider?.item.mediaSources ?? []
        }

        private var audioStreams: [MediaStream] {
            itemProvider?.audioStreams ?? []
        }

        private var subtitleStreams: [MediaStream] {
            itemProvider?.subtitleStreams ?? []
        }

        private var supportedBitrates: [PlaybackBitrate] {
            itemProvider?.supportedBitrates ?? []
        }

        private var selectedMediaSource: MediaSourceInfo? {
            itemProvider?.mediaSource
        }

        private var mediaSourceSelection: Binding<MediaSourceInfo?> {
            Binding(
                get: { selectedMediaSource },
                set: { provider.select(.mediaSource($0)) }
            )
        }

        private var audioStreamSelection: Binding<Int?> {
            Binding(
                get: {
                    itemProvider?.audioStreamIndex
                        ?? selectedMediaSource?.defaultAudioStreamIndex
                        ?? audioStreams.first?.index
                },
                set: { provider.select(.audioStreamIndex($0)) }
            )
        }

        private var subtitleStreamSelection: Binding<Int?> {
            Binding(
                get: {
                    itemProvider?.subtitleStreamIndex
                        ?? selectedMediaSource?.defaultSubtitleStreamIndex
                        ?? -1
                },
                set: { provider.select(.subtitleStreamIndex($0)) }
            )
        }

        private var bitrateSelection: Binding<PlaybackBitrate> {
            Binding(
                get: { itemProvider?.requestedBitrate ?? appMaximumBitrate },
                set: { provider.select(.bitrate($0)) }
            )
        }

        @ViewBuilder
        private var versionPicker: some View {
            Picker(
                L10n.version,
                sources: mediaSources,
                selection: mediaSourceSelection,
                noneStyle: nil
            )
            .pickerStyle(.menu)
        }

        @ViewBuilder
        private var audioPicker: some View {
            Picker(selection: audioStreamSelection) {
                ForEach(audioStreams, id: \.index) { stream in
                    Text(stream.displayTitle ?? L10n.unknown)
                        .tag(stream.index as Int?)
                }
            } label: {
                Text(L10n.audio)

                if let selectedAudioStream = audioStreams.first(where: { $0.index == audioStreamSelection.wrappedValue }) {
                    Text(selectedAudioStream.displayTitle ?? L10n.unknown)
                }
            }
            .pickerStyle(.menu)
        }

        @ViewBuilder
        private var subtitlePicker: some View {
            Picker(selection: subtitleStreamSelection) {
                ForEach(subtitleStreams.prepending(.none), id: \.index) { stream in
                    Text(stream.displayTitle ?? L10n.unknown)
                        .tag(stream.index as Int?)
                }
            } label: {
                Text(L10n.subtitles)

                if let selectedSubtitleStream = subtitleStreams
                    .first(where: { $0.index == subtitleStreamSelection.wrappedValue })
                {
                    Text(selectedSubtitleStream.displayTitle ?? L10n.unknown)
                } else {
                    Text(L10n.none)
                }
            }
            .pickerStyle(.menu)
        }

        @ViewBuilder
        private var qualityPicker: some View {
            Picker(selection: bitrateSelection) {
                ForEach(supportedBitrates, id: \.rawValue) { bitrate in
                    Text(bitrate.displayTitle)
                        .tag(bitrate)
                }
            } label: {
                Text(L10n.playbackQuality)
                Text(bitrateSelection.wrappedValue.displayTitle)
            }
            .pickerStyle(.menu)
        }

        var body: some View {
            Menu {
                if mediaSources.count > 1 {
                    versionPicker
                }

                if audioStreams.count > 1 {
                    audioPicker
                }

                if subtitleStreams.isNotEmpty {
                    subtitlePicker
                }

                if supportedBitrates.count > 1 {
                    qualityPicker
                }
            } label: {
                Label(
                    ItemActionButton.playback.displayTitle,
                    systemImage: ItemActionButton.playback.systemImage
                )
            }
            .if(!isInMenu && UIDevice.isTV) { menu in
                menu.menuStyle(.button)
            }
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(.primary, .secondary)
        }
    }
}
