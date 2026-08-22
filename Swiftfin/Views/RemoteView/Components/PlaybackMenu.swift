//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension RemoteView {

    struct PlaybackMenu: View {

        @ObservedObject
        var proxy: CastMediaPlayerProxy

        let perform: (() -> Void) -> Void

        var body: some View {
            if let mediaSources = proxy.activeItem?.mediaSources, mediaSources.count > 1 {
                Menu(L10n.version, systemImage: "list.bullet.rectangle") {
                    Picker(
                        L10n.version,
                        selection: Binding(
                            get: { proxy.session.session.playState?.mediaSourceID ?? "" },
                            set: { newValue in
                                guard let mediaSource = proxy.activeItem?.mediaSources?.first(where: { $0.id == newValue }) else { return }
                                perform { proxy.setMediaSource(mediaSource) }
                            }
                        )
                    ) {
                        ForEach(mediaSources, id: \.id) { mediaSource in
                            Text(mediaSource.displayTitle)
                                .tag(mediaSource.id ?? "")
                        }
                    }
                }
            }

            if proxy.session.supportedCommands.contains(.setAudioStreamIndex),
               let audioStreams = proxy.activeItem?.audioStreams, audioStreams.isNotEmpty
            {
                streamPicker(
                    L10n.audio,
                    systemImage: VideoPlayerActionButton.audio.systemImage,
                    streams: audioStreams,
                    selectedIndex: proxy.selectedAudioStreamIndex,
                    action: proxy.setAudioStream
                )
            }

            if proxy.session.supportedCommands.contains(.setSubtitleStreamIndex),
               let subtitleStreams = proxy.activeItem?.subtitleStreams, subtitleStreams.isNotEmpty
            {
                streamPicker(
                    L10n.subtitles,
                    systemImage: VideoPlayerActionButton.subtitles.systemImage,
                    streams: subtitleStreams.prepending(.none),
                    selectedIndex: proxy.selectedSubtitleStreamIndex,
                    action: proxy.setSubtitleStream
                )
            }

            if proxy.session.supportedCommands.contains(.setMaxStreamingBitrate) {
                Menu(L10n.maximumBitrate, systemImage: VideoPlayerActionButton.playbackSpeed.systemImage) {
                    ForEach(PlaybackBitrate.allCases, id: \.self) { bitrate in
                        Button(bitrate.displayTitle) {
                            perform { proxy.setMaxBitrate(bitrate) }
                        }
                    }
                }
            }
        }

        @ViewBuilder
        private func streamPicker(
            _ title: String,
            systemImage: String,
            streams: [MediaStream],
            selectedIndex: Int,
            action: @escaping (MediaStream) -> Void
        ) -> some View {
            let selection = Binding(
                get: { selectedIndex },
                set: { newValue in
                    guard let stream = streams.first(where: { ($0.index ?? -1) == newValue }) else { return }
                    perform { action(stream) }
                }
            )

            Menu(title, systemImage: systemImage) {
                Picker(title, selection: selection) {
                    ForEach(streams, id: \.index) { stream in
                        Text(stream.displayTitle ?? L10n.unknown)
                            .tag(stream.index ?? -1)
                    }
                }
            }
        }
    }
}
