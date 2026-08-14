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
        @ObservedObject
        var target: SessionViewModel

        let supportedCommands: [GeneralCommandType]
        let perform: (() -> Void) -> Void

        private var item: BaseItemDto? {
            proxy.displayedItem
        }

        private var selectedMediaSourceID: Binding<String> {
            Binding(
                get: { target.session.playState?.mediaSourceID ?? "" },
                set: { newValue in
                    guard let mediaSource = item?.mediaSources?.first(where: { $0.id == newValue }) else { return }
                    perform { proxy.setMediaSource(mediaSource) }
                }
            )
        }

        private var selectedAudioStreamIndex: Binding<Int> {
            Binding(
                get: { proxy.selectedAudioStreamIndex },
                set: { newValue in
                    guard let stream = item?.audioStreams.first(where: { $0.index == newValue }) else { return }
                    perform { proxy.setAudioStream(stream) }
                }
            )
        }

        private var selectedSubtitleStreamIndex: Binding<Int> {
            Binding(
                get: { proxy.selectedSubtitleStreamIndex },
                set: { newValue in
                    if newValue == -1 {
                        perform { proxy.setSubtitleStream(.init(index: -1)) }
                    } else if let stream = item?.subtitleStreams.first(where: { $0.index == newValue }) {
                        perform { proxy.setSubtitleStream(stream) }
                    }
                }
            )
        }

        var body: some View {
            if let mediaSources = item?.mediaSources, mediaSources.count > 1 {
                Menu(L10n.version, systemImage: "list.bullet.rectangle") {
                    Picker(L10n.version, selection: selectedMediaSourceID) {
                        ForEach(mediaSources, id: \.id) { mediaSource in
                            Text(mediaSource.displayTitle)
                                .tag(mediaSource.id ?? "")
                        }
                    }
                }
            }

            if supportedCommands.contains(.setAudioStreamIndex), let audioStreams = item?.audioStreams,
               audioStreams.isNotEmpty
            {
                Menu(L10n.audio, systemImage: "speaker.wave.2") {
                    Picker(L10n.audio, selection: selectedAudioStreamIndex) {
                        ForEach(audioStreams, id: \.index) { stream in
                            Text(stream.displayTitle ?? L10n.unknown)
                                .tag(stream.index ?? -1)
                        }
                    }
                }
            }

            if supportedCommands.contains(.setSubtitleStreamIndex), let subtitleStreams = item?.subtitleStreams,
               subtitleStreams.isNotEmpty
            {
                Menu(L10n.subtitles, systemImage: "captions.bubble") {
                    Picker(L10n.subtitles, selection: selectedSubtitleStreamIndex) {
                        Text(L10n.none)
                            .tag(-1)

                        ForEach(subtitleStreams, id: \.index) { stream in
                            Text(stream.displayTitle ?? L10n.unknown)
                                .tag(stream.index ?? -1)
                        }
                    }
                }
            }

            if supportedCommands.contains(.setMaxStreamingBitrate) {
                Menu(L10n.maximumBitrate, systemImage: "speedometer") {
                    ForEach(PlaybackBitrate.allCases, id: \.self) { bitrate in
                        Button(bitrate.displayTitle) {
                            perform {
                                target.sendFullGeneralCommand(
                                    GeneralCommand(
                                        arguments: ["Bitrate": "\(bitrate.rawValue)"],
                                        name: .setMaxStreamingBitrate
                                    )
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}
