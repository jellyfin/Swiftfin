//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer {

    struct SmallMenuOverlay: View {

        enum MenuSection: String, Displayable {
            case audio
            case chapters
            case playbackSpeed
            case subtitles

            var displayTitle: String {
                switch self {
                case .audio:
                    return "Audio"
                case .chapters:
                    return "Chapters"
                case .playbackSpeed:
                    return "Playback Speed"
                case .subtitles:
                    return "Subtitles"
                }
            }
        }

        @EnvironmentObject
        private var videoPlayerManager: VideoPlayerManager
        @EnvironmentObject
        private var viewModel: VideoPlayerViewModel

        @FocusState
        private var focusedSection: MenuSection?

        @State
        private var lastFocusedSection: MenuSection?

        @StateObject
        private var focusGuide: FocusGuide = .init()

        @ViewBuilder
        private var subtitleMenu: some View {
            HStack {
                ForEach(viewModel.subtitleStreams, id: \.self) { mediaStream in
                    Button {} label: {
                        if videoPlayerManager.subtitleTrackIndex == mediaStream.index {
                            Label(mediaStream.displayTitle ?? L10n.noTitle, systemImage: "checkmark")
                        } else {
                            Text(mediaStream.displayTitle ?? L10n.noTitle)
                        }
                    }
                }
            }
            .frame(height: 80)
            .padding(.horizontal, 50)
            .padding(.top)
            .padding(.bottom, 45)
            .focusGuide(
                focusGuide,
                tag: "contents",
                top: "sections"
            )
        }

        var body: some View {
            VStack {

                Spacer()

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        if !viewModel.subtitleStreams.isEmpty {
                            SectionButton(
                                section: .subtitles,
                                focused: $focusedSection,
                                lastFocused: $lastFocusedSection
                            )
                        }

                        if !viewModel.audioStreams.isEmpty {
                            SectionButton(
                                section: .audio,
                                focused: $focusedSection,
                                lastFocused: $lastFocusedSection
                            )
                        }

                        SectionButton(
                            section: .playbackSpeed,
                            focused: $focusedSection,
                            lastFocused: $lastFocusedSection
                        )

                        if !viewModel.chapters.isEmpty {
                            SectionButton(
                                section: .chapters,
                                focused: $focusedSection,
                                lastFocused: $lastFocusedSection
                            )
                        }
                    }
                    .focusGuide(
                        focusGuide,
                        tag: "sections",
                        onContentFocus: { focusedSection = lastFocusedSection },
                        bottom: "contents"
                    )
                    .frame(height: 70)
                    .padding(.horizontal, 50)
                    .padding(.top)
                    .padding(.bottom, 45)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    switch lastFocusedSection {
                    case .subtitles:
                        subtitleMenu
                    default:
                        Button {
                            Text("None")
                        }
                    }
                }
            }
            .ignoresSafeArea()
            .background {
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black.opacity(0.8), location: 1),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .onChange(of: focusedSection) { newValue in
                guard let newValue else { return }
                lastFocusedSection = newValue
            }
        }

        struct SectionButton: View {

            let section: MenuSection
            let focused: FocusState<MenuSection?>.Binding
            let lastFocused: Binding<MenuSection?>

            var body: some View {
                Button {
                    Text(section.displayTitle)
                        .fontWeight(.semibold)
                        .fixedSize()
                        .padding()
                        .if(lastFocused.wrappedValue == section) { text in
                            text
                                .background(.white)
                                .foregroundColor(.black)
                        }
                }
                .buttonStyle(.plain)
                .background(.clear)
                .focused(focused, equals: section)
            }
        }
    }
}
