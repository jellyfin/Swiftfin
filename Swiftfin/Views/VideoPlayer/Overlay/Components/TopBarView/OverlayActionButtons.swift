//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ItemVideoPlayer.Overlay {
    
    struct ActionButtons: View {
        
        @ObservedObject
        var viewModel: ItemVideoPlayerViewModel
        
        var body: some View {
            HStack(spacing: 20) {
                if !viewModel.subtitleStreams.isEmpty {
                    Button {
                        viewModel.subtitlesEnabled.toggle()
                    } label: {
                        if viewModel.subtitlesEnabled {
                            Image(systemName: "captions.bubble.fill")
                        } else {
                            Image(systemName: "captions.bubble")
                        }
                    }
                    .disabled(viewModel.selectedSubtitleTrackIndex == -1)
                    .foregroundColor(viewModel.selectedSubtitleTrackIndex == -1 ? .gray : .white)
                }
                
                Button {
                    if viewModel.isAspectFilled {
                        viewModel.isAspectFilled.toggle()
                        UIView.animate(withDuration: 0.2) {
                            viewModel.eventSubject.send(.aspectFill(0))
                        }
                    } else {
                        viewModel.isAspectFilled.toggle()
                        UIView.animate(withDuration: 0.2) {
                            viewModel.eventSubject.send(.aspectFill(1))
                        }
                    }
                } label: {
                    if viewModel.isAspectFilled {
                        Image(systemName: "arrow.down.right.and.arrow.up.left")
                    } else {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                    }
                }
                
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
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
}
