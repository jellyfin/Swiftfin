//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

// TODO: Needs replacement/reworking
struct SmallMediaStreamSelectionView: View {

    enum Layer: Hashable {
        case subtitles
        case audio
        case playbackSpeed
        case chapters
    }

    enum MediaSection: Hashable {
        case titles
        case items
    }

    @ObservedObject
    var viewModel: VideoPlayerViewModel
    private let chapterImages: [URL]

    @State
    private var updateFocusedLayer: Layer = .subtitles
    @State
    private var lastFocusedLayer: Layer = .subtitles

    @FocusState
    private var subtitlesFocused: Bool
    @FocusState
    private var audioFocused: Bool
    @FocusState
    private var playbackSpeedFocused: Bool
    @FocusState
    private var chaptersFocused: Bool
    @FocusState
    private var focusedSection: MediaSection?
    @FocusState
    private var focusedLayer: Layer? {
        willSet {
            updateFocusedLayer = newValue!

            if focusedSection == .titles {
                lastFocusedLayer = newValue!
            }
        }
    }

    init(viewModel: VideoPlayerViewModel) {
        self.viewModel = viewModel
        self.chapterImages = viewModel.item.getChapterImage(maxWidth: 500)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                gradient: Gradient(colors: [.clear, .black.opacity(0.8), .black]),
                startPoint: .top,
                endPoint: .bottom
            )
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
                                L10n.subtitles.text
                            }
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.black)
                        } else {
                            HStack(spacing: 15) {
                                Image(systemName: "captions.bubble")
                                L10n.subtitles.text
                            }
                            .padding()
                        }
                    }
                    .buttonStyle(.plain)
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
                                L10n.audio.text
                            }
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.black)
                        } else {
                            HStack(spacing: 15) {
                                Image(systemName: "speaker.wave.3")
                                L10n.audio.text
                            }
                            .padding()
                        }
                    }
                    .buttonStyle(.plain)
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
                                L10n.playbackSpeed.text
                            }
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.black)
                        } else {
                            HStack(spacing: 15) {
                                Image(systemName: "speedometer")
                                L10n.playbackSpeed.text
                            }
                            .padding()
                        }
                    }
                    .buttonStyle(.plain)
                    .background(Color.clear)
                    .focused($focusedLayer, equals: .playbackSpeed)
                    .focused($playbackSpeedFocused)
                    .onChange(of: playbackSpeedFocused) { isFocused in
                        if isFocused {
                            focusedLayer = .playbackSpeed
                        }
                    }

                    // MARK: Chapters Header

                    if !viewModel.chapters.isEmpty {
                        Button {
                            updateFocusedLayer = .chapters
                            focusedLayer = .chapters
                        } label: {
                            if updateFocusedLayer == .chapters {
                                HStack(spacing: 15) {
                                    Image(systemName: "list.dash")
                                    L10n.chapters.text
                                }
                                .padding()
                                .background(Color.white)
                                .foregroundColor(.black)
                            } else {
                                HStack(spacing: 15) {
                                    Image(systemName: "list.dash")
                                    L10n.chapters.text
                                }
                                .padding()
                            }
                        }
                        .buttonStyle(.plain)
                        .background(Color.clear)
                        .focused($focusedLayer, equals: .chapters)
                        .focused($chaptersFocused)
                        .onChange(of: chaptersFocused) { isFocused in
                            if isFocused {
                                focusedLayer = .chapters
                            }
                        }
                    }

                    Spacer()
                }
                .padding()
                .focusSection()
                .focused($focusedSection, equals: .titles)
                .onChange(of: focusedSection) { _ in
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

                    subtitleMenuView
                } else if updateFocusedLayer == .audio && lastFocusedLayer == .audio {
                    // MARK: Audio

                    audioMenuView
                } else if updateFocusedLayer == .playbackSpeed && lastFocusedLayer == .playbackSpeed {
                    // MARK: Playback Speed

                    playbackSpeedMenuView
                } else if updateFocusedLayer == .chapters && lastFocusedLayer == .chapters {
                    // MARK: Chapters

                    chaptersMenuView
                }
            }
        }
    }

    @ViewBuilder
    private var subtitleMenuView: some View {
        ScrollView(.horizontal) {
            HStack {
                if viewModel.subtitleStreams.isEmpty {
                    Button {} label: {
                        L10n.none.text
                    }
                } else {
                    ForEach(viewModel.subtitleStreams, id: \.self) { subtitleStream in
                        Button {
                            viewModel.selectedSubtitleStreamIndex = subtitleStream.index ?? -1
                        } label: {
                            if subtitleStream.index == viewModel.selectedSubtitleStreamIndex {
                                Label(subtitleStream.displayTitle ?? L10n.noTitle, systemImage: "checkmark")
                            } else {
                                Text(subtitleStream.displayTitle ?? L10n.noTitle)
                            }
                        }
                    }
                }
            }
            .padding(.vertical)
            .focusSection()
            .focused($focusedSection, equals: .items)
        }
    }

    @ViewBuilder
    private var audioMenuView: some View {
        ScrollView(.horizontal) {
            HStack {
                if viewModel.audioStreams.isEmpty {
                    Button {} label: {
                        Text("None")
                    }
                } else {
                    ForEach(viewModel.audioStreams, id: \.self) { audioStream in
                        Button {
                            viewModel.selectedAudioStreamIndex = audioStream.index ?? -1
                        } label: {
                            if audioStream.index == viewModel.selectedAudioStreamIndex {
                                Label(audioStream.displayTitle ?? L10n.noTitle, systemImage: "checkmark")
                            } else {
                                Text(audioStream.displayTitle ?? L10n.noTitle)
                            }
                        }
                    }
                }
            }
            .padding(.vertical)
            .focusSection()
            .focused($focusedSection, equals: .items)
        }
    }

    @ViewBuilder
    private var playbackSpeedMenuView: some View {
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

    @ViewBuilder
    private var chaptersMenuView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ScrollViewReader { reader in
                HStack {
                    ForEach(0 ..< viewModel.chapters.count, id: \.self) { chapterIndex in
                        VStack(alignment: .leading) {
                            Button {
                                viewModel.playerOverlayDelegate?.didSelectChapter(viewModel.chapters[chapterIndex])
                            } label: {
                                ImageView(chapterImages[chapterIndex])
                                    .cornerRadius(10)
                                    .frame(width: 350, height: 210)
                            }
                            .buttonStyle(.card)

                            VStack(alignment: .leading, spacing: 5) {

                                Text(viewModel.chapters[chapterIndex].name ?? L10n.noTitle)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)

                                Text(viewModel.chapters[chapterIndex].timestampLabel)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color(UIColor.systemBlue))
                                    .padding(.vertical, 2)
                                    .padding(.horizontal, 4)
                                    .background {
                                        Color(UIColor.darkGray).opacity(0.2).cornerRadius(4)
                                    }
                            }
                        }
                        .id(viewModel.chapters[chapterIndex])
                    }
                }
                .padding(.top)
                .onAppear {
                    reader.scrollTo(viewModel.currentChapter)
                }
            }
        }
    }
}
