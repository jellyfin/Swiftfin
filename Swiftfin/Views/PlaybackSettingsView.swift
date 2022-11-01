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

struct PlaybackSettingsView: View {

    @EnvironmentObject
    private var viewModel: VideoPlayerViewModel
    @EnvironmentObject
    private var router: PlaybackSettingsCoordinator.Router

    @Environment(\.audioOffset)
    @Binding
    private var audioOffset
    @Environment(\.presentingPlaybackSettings)
    @Binding
    private var presentingPlaybackSettings
    @Environment(\.subtitleOffset)
    @Binding
    private var subtitleOffset

    var body: some View {
        Form {
            Section {
                Button {
                    router.route(to: \.overlaySettings)
                } label: {
                    Text("Video Player")
                }

                Button {
                    router.route(to: \.playbackInformation)
                } label: {
                    Text("Playback Information")
                }

            } header: {
                EmptyView()
            }
            
            Stepper(value: _audioOffset.wrappedValue, in: -30_000 ... 30_000, step: 100) {
                HStack {
                    Text("Audio Offset")
                    
                    Spacer()
                    
                    Text("\(audioOffset)")
                        .foregroundColor(.secondary)
                }
            }
            
            Stepper(value: _subtitleOffset.wrappedValue, in: -30_000 ... 30_000, step: 100) {
                HStack {
                    Text("Subtitle Offset")
                    
                    Spacer()
                    
                    Text("\(subtitleOffset)")
                        .foregroundColor(.secondary)
                }
            }

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
//                    withAnimation {
                    presentingPlaybackSettings = false
//                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
//                        .frame(width: 44, height: 50)
                }
            }
        }
    }
}
