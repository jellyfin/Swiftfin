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

extension ItemView.ActionButtons {

    struct Playback: View {

        @Default(.VideoPlayer.Playback.appMaximumBitrate)
        private var appMaximumBitrate

        @ViewContextContains(.isInMenu)
        private var isInMenu

        @EnvironmentObject
        private var provider: ItemContentGroupProvider

        static func hasOptions(for provider: ItemContentGroupProvider) -> Bool {
            mediaSources(for: provider).count > 1
                || audioStreams(for: provider).count > 1
                || subtitleStreams(for: provider).isNotEmpty
                || supportedBitrates(for: provider).count > 1
        }

        private static func mediaSources(for provider: ItemContentGroupProvider) -> [MediaSourceInfo] {
            provider.mediaPlayerItemProvider?.item.mediaSources ?? []
        }

        private static func audioStreams(for provider: ItemContentGroupProvider) -> [MediaStream] {
            selectedMediaSource(for: provider)?.audioStreams?.filter { $0.isExternal != true } ?? []
        }

        private static func subtitleStreams(for provider: ItemContentGroupProvider) -> [MediaStream] {
            selectedMediaSource(for: provider)?.subtitleStreams ?? []
        }

        private static func supportedBitrates(for provider: ItemContentGroupProvider) -> [PlaybackBitrate] {
            selectedMediaSource(for: provider)?.supportedBitrates ?? []
        }

        private static func selectedMediaSource(for provider: ItemContentGroupProvider) -> MediaSourceInfo? {
            provider.mediaPlayerItemProvider?.mediaSource
        }

        private var mediaSources: [MediaSourceInfo] {
            Self.mediaSources(for: provider)
        }

        private var audioStreams: [MediaStream] {
            Self.audioStreams(for: provider)
        }

        private var subtitleStreams: [MediaStream] {
            Self.subtitleStreams(for: provider)
        }

        private var supportedBitrates: [PlaybackBitrate] {
            Self.supportedBitrates(for: provider)
        }

        private var selectedMediaSource: MediaSourceInfo? {
            Self.selectedMediaSource(for: provider)
        }

        private var mediaSourceSelection: Binding<MediaSourceInfo?> {
            Binding(
                get: { selectedMediaSource },
                set: provider.selectMediaSource
            )
        }

        private var audioStreamSelection: Binding<Int?> {
            Binding(
                get: {
                    provider.mediaPlayerItemProvider?.audioStreamIndex
                        ?? selectedMediaSource?.defaultAudioStreamIndex
                        ?? audioStreams.first?.index
                },
                set: provider.selectAudioStreamIndex
            )
        }

        private var subtitleStreamSelection: Binding<Int?> {
            Binding(
                get: {
                    provider.mediaPlayerItemProvider?.subtitleStreamIndex
                        ?? selectedMediaSource?.defaultSubtitleStreamIndex
                        ?? -1
                },
                set: provider.selectSubtitleStreamIndex
            )
        }

        private var bitrateSelection: Binding<PlaybackBitrate> {
            Binding(
                get: { provider.mediaPlayerItemProvider?.requestedBitrate ?? appMaximumBitrate },
                set: provider.selectBitrate
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
                ItemView.ActionButtonLabel(.playback)
            }
            .if(!isInMenu && UIDevice.isTV) { menu in
                menu.menuStyle(.button)
            }
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(.primary, .secondary)
        }
    }
}
