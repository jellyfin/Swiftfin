//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import Stinsen
import SwiftUI
import VLCUI

// TODO: organize

struct PlaybackSettingsView: View {

    @EnvironmentObject
    private var router: PlaybackSettingsCoordinator.Router
    @EnvironmentObject
    private var splitContentViewProxy: SplitContentViewProxy
    @EnvironmentObject
    private var viewModel: VideoPlayerViewModel

    @Environment(\.audioOffset)
    @Binding
    private var audioOffset
    @Environment(\.subtitleOffset)
    @Binding
    private var subtitleOffset
    
    private func millisecondFormat(from value: Int) -> String {
        let negative = value < 0
        let value = abs(value)
        let seconds = "\(value / 1000)"
        let milliseconds = "\(value % 1000)".first ?? "0"
        
        return seconds
            .appending(".")
            .appending(milliseconds)
            .appending("s")
            .prepending("-", if: negative)
    }

    var body: some View {
        Form {
            Section {
                
                ChevronButton(title: L10n.videoPlayer)
                    .onSelect {
                        router.route(to: \.videoPlayerSettings)
                    }
                
//                ChevronButton(title: "Playback Information")
//                    .onSelect {
//                        router.route(to: \.playbackInformation)
//                    }
            } header: {
                EmptyView()
            }
            
            // TODO: second formatting
            BasicStepper(
                title: "Audio Offset",
                value: _audioOffset.wrappedValue,
                range: -30_000 ... 30_000,
                step: 100
            )
            .valueFormatter(millisecondFormat(from:))
            
            BasicStepper(
                title: "Subtitle Offset",
                value: _subtitleOffset.wrappedValue,
                range: -30_000 ... 30_000,
                step: 100
            )
            .valueFormatter(millisecondFormat(from:))

            Section("Audio") {
                ForEach(viewModel.audioStreams, id: \.displayTitle) { mediaStream in
                    ChevronButton(title: mediaStream.displayTitle ?? .emptyDash)
                        .onSelect {
                            router.route(to: \.mediaStreamInfo, mediaStream)
                        }
                }
            }

            Section("Subtitle") {
                ForEach(viewModel.subtitleStreams, id: \.displayTitle) { mediaStream in
                    ChevronButton(title: mediaStream.displayTitle ?? .emptyDash)
                        .onSelect {
                            router.route(to: \.mediaStreamInfo, mediaStream)
                        }
                }
            }
        }
        .navigationTitle("Playback")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarLeading) {
                Button {
                    splitContentViewProxy.hide()
                } label: {
                    Image(systemName: "xmark.circle.fill")
//                        .resizable()
//                        .frame(width: 44, height: 50)
                }
            }
        }
    }
}
