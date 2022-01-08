//
 /* 
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import JellyfinAPI
import SwiftUI

// TODO: Needs replacement/reworking
struct SmallMediaStreamSelectionView: View {
    
    enum Layer: Hashable {
        case subtitles
        case audio
        case playbackSpeed
    }
    
    enum MediaSection: Hashable {
        case titles
        case items
    }
    
    @ObservedObject var viewModel: VideoPlayerViewModel
    
    @State private var updateFocusedLayer: Layer = .subtitles
    
    @FocusState private var subtitlesFocused: Bool
    @FocusState private var audioFocused: Bool
    @FocusState private var playbackSpeedFocused: Bool
    @FocusState private var focusedSection: MediaSection?
    @FocusState private var focusedLayer: Layer? {
        willSet {
            updateFocusedLayer = newValue!
            
            if focusedSection == .titles {
                lastFocusedLayer = newValue!
            }
        }
    }
    
    @State private var lastFocusedLayer: Layer = .subtitles
    
    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(gradient: Gradient(colors: [.clear, .black.opacity(0.8), .black]),
                           startPoint: .top,
                           endPoint: .bottom)
                .ignoresSafeArea()
                .frame(height: 300)

            VStack {

                Spacer()

                HStack {
                    
                    // MARK: Subtitle Header
                    Button {
                        updateFocusedLayer = .subtitles
                        focusedLayer = .subtitles
                    } label: {
                        if updateFocusedLayer == .subtitles {
                            HStack(spacing: 15) {
                                Image(systemName: "captions.bubble")
                                Text("Subtitles")
                            }
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.black)
                        } else {
                            HStack(spacing: 15) {
                                Image(systemName: "captions.bubble")
                                Text("Subtitles")
                            }
                            .padding()
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .background(Color.clear)
                    .focused($focusedLayer, equals: .subtitles)
                    .focused($subtitlesFocused)
                    .onChange(of: subtitlesFocused) { isFocused in
                        if isFocused {
                            focusedLayer = .subtitles
                        }
                    }
                    
                    // MARK: Audio Header
                    Button {
                        updateFocusedLayer = .audio
                        focusedLayer = .audio
                    } label: {
                        if updateFocusedLayer == .audio {
                            HStack(spacing: 15) {
                                Image(systemName: "speaker.wave.3")
                                Text("Audio")
                            }
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.black)
                        } else {
                            HStack(spacing: 15) {
                                Image(systemName: "speaker.wave.3")
                                Text("Audio")
                            }
                            .padding()
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .background(Color.clear)
                    .focused($focusedLayer, equals: .audio)
                    .focused($audioFocused)
                    .onChange(of: audioFocused) { isFocused in
                        if isFocused {
                            focusedLayer = .audio
                        }
                    }
                    
                    // MARK: Playback Speed Header
                    Button {
                        updateFocusedLayer = .playbackSpeed
                        focusedLayer = .playbackSpeed
                    } label: {
                        if updateFocusedLayer == .playbackSpeed {
                            HStack(spacing: 15) {
                                Image(systemName: "speedometer")
                                Text("Playback Speed")
                            }
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.black)
                        } else {
                            HStack(spacing: 15) {
                                Image(systemName: "speedometer")
                                Text("Playback Speed")
                            }
                            .padding()
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .background(Color.clear)
                    .focused($focusedLayer, equals: .playbackSpeed)
                    .focused($playbackSpeedFocused)
                    .onChange(of: playbackSpeedFocused) { isFocused in
                        if isFocused {
                            focusedLayer = .playbackSpeed
                        }
                    }
                    
                    Spacer()
                }
                .padding()
                .focusSection()
                .focused($focusedSection, equals: .titles)
                .onChange(of: focusedSection) { newSection in
                    if focusedSection == .titles {
                        if lastFocusedLayer == .subtitles {
                            subtitlesFocused = true
                        } else if lastFocusedLayer == .audio {
                            audioFocused = true
                        } else if lastFocusedLayer == .playbackSpeed {
                            playbackSpeedFocused = true
                        }
                    }
                }
                
                if updateFocusedLayer == .subtitles && lastFocusedLayer == .subtitles {
                    // MARK: Subtitles
                    
                    ScrollView(.horizontal) {
                        HStack {
                            if viewModel.subtitleStreams.isEmpty {
                                Button {
                                    
                                } label: {
                                    Text("None")
                                }
                            } else {
                                ForEach(viewModel.subtitleStreams, id: \.self) { subtitleStream in
                                    Button {
                                        viewModel.selectedSubtitleStreamIndex = subtitleStream.index ?? -1
                                    } label: {
                                        if subtitleStream.index == viewModel.selectedSubtitleStreamIndex {
                                            Label(subtitleStream.displayTitle ?? "No Title", systemImage: "checkmark")
                                        } else {
                                            Text(subtitleStream.displayTitle ?? "No Title")
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical)
                        .focusSection()
                        .focused($focusedSection, equals: .items)
                    }
                } else if updateFocusedLayer == .audio && lastFocusedLayer == .audio {
                    // MARK: Audio
                    
                    ScrollView(.horizontal) {
                        HStack {
                            if viewModel.audioStreams.isEmpty {
                                Button {
                                    
                                } label: {
                                    Text("None")
                                }
                            } else {
                                ForEach(viewModel.audioStreams, id: \.self) { audioStream in
                                    Button {
                                        viewModel.selectedAudioStreamIndex = audioStream.index ?? -1
                                    } label: {
                                        if audioStream.index == viewModel.selectedAudioStreamIndex {
                                            Label(audioStream.displayTitle ?? "No Title", systemImage: "checkmark")
                                        } else {
                                            Text(audioStream.displayTitle ?? "No Title")
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical)
                        .focusSection()
                        .focused($focusedSection, equals: .items)
                    }
                } else if updateFocusedLayer == .playbackSpeed && lastFocusedLayer == .playbackSpeed {
                    // MARK: Rates
                    
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(PlaybackSpeed.allCases, id: \.self) { playbackSpeed in
                                Button {
                                    viewModel.playbackSpeed = playbackSpeed
                                } label: {
                                    if playbackSpeed == viewModel.playbackSpeed {
                                        Label(playbackSpeed.displayTitle, systemImage: "checkmark")
                                    } else {
                                        Text(playbackSpeed.displayTitle)
                                    }
                                }
                            }
                        }
                        .padding(.vertical)
                        .focusSection()
                        .focused($focusedSection, equals: .items)
                    }
                }
            }
        }
    }
}
