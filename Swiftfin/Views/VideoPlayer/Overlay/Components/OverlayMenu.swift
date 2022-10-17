//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI
import VLCUI

extension ItemVideoPlayer.Overlay {

    struct OverlayMenu: View {

        @Environment(\.currentOverlayType)
        @Binding
        private var currentOverlayType
        @Environment(\.presentingPlaybackSettings)
        @Binding
        private var presentingPlaybackSettings

        @EnvironmentObject
        private var overlayTimer: TimerProxy
        @EnvironmentObject
        private var videoPlayerManager: VideoPlayerManager
        @EnvironmentObject
        private var videoPlayerProxy: VLCVideoPlayer.Proxy
        @EnvironmentObject
        private var viewModel: VideoPlayerViewModel

        @ViewBuilder
        private var subtitleTrackMenu: some View {
            Menu {
                ForEach(viewModel.subtitleStreams.prepending(.none), id: \.self) { subtitleTrack in
                    Button {
                        videoPlayerProxy.setSubtitleTrack(.absolute(subtitleTrack.index ?? -1))
                    } label: {
                        if videoPlayerManager.subtitleTrackIndex == subtitleTrack.index ?? -1 {
                            Label(subtitleTrack.displayTitle ?? .emptyDash, systemImage: "checkmark")
                        } else {
                            Text(subtitleTrack.displayTitle ?? .emptyDash)
                        }
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "captions.bubble")
                    L10n.subtitles.text
                }
            }
        }

        @ViewBuilder
        private var audioTrackMenu: some View {
            Menu {
                ForEach(viewModel.audioStreams.prepending(.none), id: \.self) { audioTrack in
                    Button {
                        videoPlayerProxy.setAudioTrack(.absolute(audioTrack.index ?? -1))
                    } label: {
                        if videoPlayerManager.audioTrackIndex == audioTrack.index ?? -1 {
                            Label(audioTrack.displayTitle ?? .emptyDash, systemImage: "checkmark")
                        } else {
                            Text(audioTrack.displayTitle ?? .emptyDash)
                        }
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "speaker.wave.3")
                    L10n.audio.text
                }
            }
        }

        @ViewBuilder
        private var playbackSpeedMenu: some View {
            Menu {
                ForEach(PlaybackSpeed.allCases, id: \.self) { speed in
                    Button {
                        videoPlayerProxy.setRate(.absolute(Float(speed.rawValue)))
                    } label: {
                        if Float(speed.rawValue) == videoPlayerManager.rate {
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
        }

        @ViewBuilder
        private var chaptersButton: some View {
            Button {
                currentOverlayType = .chapters
            } label: {
                HStack {
                    L10n.chapters.text

                    Image(systemName: "list.dash")
                }
            }
        }

        @ViewBuilder
        private var advancedButton: some View {
            Button {
                withAnimation {
                    presentingPlaybackSettings = true
                }

                overlayTimer.start(3)
            } label: {
                HStack {
                    Text("Advanced")

                    Image(systemName: "gearshape.fill")
                }
            }
        }

        var body: some View {
            Menu {
                subtitleTrackMenu

                audioTrackMenu

                playbackSpeedMenu

                if !viewModel.chapters.isEmpty {
                    chaptersButton
                }

                advancedButton
                    .onAppear {
                        overlayTimer.stop()
                    }
                    .onDisappear {
                        overlayTimer.start(3)
                    }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .frame(width: 50, height: 50)
        }
    }
}
