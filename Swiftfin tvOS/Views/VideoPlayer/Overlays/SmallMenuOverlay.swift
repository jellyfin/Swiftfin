//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer {

    struct SmallMenuOverlay: View {

        enum MenuSection: String, Displayable {
            case audio
            case playbackSpeed
            case subtitles

            var displayTitle: String {
                switch self {
                case .audio:
                    return L10n.audio
                case .playbackSpeed:
                    return L10n.playbackSpeed
                case .subtitles:
                    return L10n.subtitles
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
        private var lastFocusedSection: MenuSection = .subtitles

        @StateObject
        private var focusGuide: FocusGuide = .init()

        @ViewBuilder
        private var subtitleMenu: some View {
            HStack {
                ForEach(viewModel.subtitleStreams, id: \.self) { mediaStream in
                    Button {
                        videoPlayerManager.subtitleTrackIndex = mediaStream.index ?? -1
                        videoPlayerManager.proxy.setSubtitleTrack(.absolute(mediaStream.index ?? -1))
                    } label: {
                        Label(
                            mediaStream.displayTitle ?? L10n.noTitle,
                            systemImage: videoPlayerManager.subtitleTrackIndex == mediaStream.index ? "checkmark.circle.fill" : "circle"
                        )
                    }
                }
            }
            .modifier(MenuStyle(focusGuide: focusGuide))
        }

        @ViewBuilder
        private var audioMenu: some View {
            HStack {
                ForEach(viewModel.audioStreams, id: \.self) { mediaStream in
                    Button {
                        videoPlayerManager.audioTrackIndex = mediaStream.index ?? -1
                        videoPlayerManager.proxy.setAudioTrack(.absolute(mediaStream.index ?? -1))
                    } label: {
                        Label(
                            mediaStream.displayTitle ?? L10n.noTitle,
                            systemImage: videoPlayerManager.audioTrackIndex == mediaStream.index ? "checkmark.circle.fill" : "circle"
                        )
                    }
                }
            }
            .modifier(MenuStyle(focusGuide: focusGuide))
        }

        @ViewBuilder
        private var playbackSpeedMenu: some View {
            HStack {
                ForEach(PlaybackSpeed.allCases, id: \.self) { speed in
                    Button {
                        videoPlayerManager.playbackSpeed = speed
                        videoPlayerManager.proxy.setRate(.absolute(Float(speed.rawValue)))
                    } label: {
                        Label(
                            speed.displayTitle,
                            systemImage: speed == videoPlayerManager.playbackSpeed ? "checkmark.circle.fill" : "circle"
                        )
                    }
                }
            }
            .modifier(MenuStyle(focusGuide: focusGuide))
        }

        var body: some View {
            VStack {

                Spacer()

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        if viewModel.subtitleStreams.isNotEmpty {
                            SectionButton(
                                section: .subtitles,
                                focused: $focusedSection,
                                lastFocused: $lastFocusedSection
                            )
                        }

                        if viewModel.audioStreams.isNotEmpty {
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
                    case .audio:
                        audioMenu
                    case .playbackSpeed:
                        playbackSpeedMenu
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
            .onChange(of: focusedSection) { _, newValue in
                guard let newValue else { return }
                lastFocusedSection = newValue
            }
        }

        struct SectionButton: View {

            let section: MenuSection
            let focused: FocusState<MenuSection?>.Binding
            let lastFocused: Binding<MenuSection>

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

        struct MenuStyle: ViewModifier {
            var focusGuide: FocusGuide

            func body(content: Content) -> some View {
                content
                    .focusGuide(
                        focusGuide,
                        tag: "contents",
                        top: "sections"
                    )
                    .frame(height: 80)
                    .padding(.horizontal, 50)
                    .padding(.top)
                    .padding(.bottom, 45)
            }
        }
    }
}
