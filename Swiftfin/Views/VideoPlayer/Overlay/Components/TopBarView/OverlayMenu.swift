//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct OverlayMenu: View {
    
    @EnvironmentObject
    private var viewModel: ItemVideoPlayerViewModel
    @Environment(\.currentOverlayType)
    @Binding
    private var currentOverlayType
    
    var body: some View {
        Menu {
            Menu {
                ForEach(viewModel.playerSubtitleTracks.keys.sorted(), id: \.self) { subtitleStreamIndex in
                    Button {
                        viewModel.eventSubject.send(.setSubtitleTrack(.absolute(subtitleStreamIndex)))
                    } label: {
                        if subtitleStreamIndex == viewModel.selectedSubtitleTrackIndex {
                            Label(viewModel.playerSubtitleTracks[subtitleStreamIndex] ?? L10n.noTitle, systemImage: "checkmark")
                        } else {
                            Text(viewModel.playerSubtitleTracks[subtitleStreamIndex] ?? L10n.noTitle)
                        }
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "captions.bubble")
                    L10n.subtitles.text
                }
            }

            Menu {
                ForEach(viewModel.playerAudioTracks.keys.sorted(), id: \.self) { audioStreamIndex in
                    Button {
                        viewModel.eventSubject.send(.setAudioTrack(.absolute(audioStreamIndex)))
                    } label: {
                        Text(viewModel.playerAudioTracks[audioStreamIndex] ?? L10n.noTitle)
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "speaker.wave.3")
                    L10n.audio.text
                }
            }

            Menu {
                ForEach(PlaybackSpeed.allCases, id: \.self) { speed in
                    Button {
                        viewModel.eventSubject.send(.fastForward(.absolute(Float(speed.rawValue))))
                        viewModel.playerPlaybackSpeed = speed
                    } label: {
                        if speed == viewModel.playerPlaybackSpeed {
                            Label(speed.displayTitle, systemImage: "checkmark")
                        } else {
                            Text(speed.displayTitle)
                        }
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "speedometer")
                    L10n.playbackSpeed.text
                }
            }
            
            Button {
                currentOverlayType = .chapters
            } label: {
                HStack {
                    L10n.chapters.text
                    
                    Image(systemName: "list.dash")
                }
            }
            
            Button {
                viewModel.presentSettings = true
            } label: {
                HStack {
                    Text("Advanced")
                    
                    Image(systemName: "gearshape.fill")
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
        .frame(width: 50, height: 50)
    }
}
