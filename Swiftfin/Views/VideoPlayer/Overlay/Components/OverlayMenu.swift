//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI
import VLCUI

extension VideoPlayer.Overlay {

    struct OverlayMenu: View {
        
        @Environment(\.currentOverlayType)
        @Binding
        private var currentOverlayType

        @EnvironmentObject
        private var overlayTimer: TimerProxy
        @EnvironmentObject
        private var router: ItemVideoPlayerCoordinator.Router
        @EnvironmentObject
        private var splitContentViewProxy: SplitContentViewProxy
        @EnvironmentObject
        private var videoPlayerManager: VideoPlayerManager
        @EnvironmentObject
        private var videoPlayerProxy: VLCVideoPlayer.Proxy
        @EnvironmentObject
        private var viewModel: VideoPlayerViewModel

        @ViewBuilder
        private var subtitleTrackMenu: some View {
            Menu {
                ForEach(viewModel.subtitleStreams.prepending(.none), id: \.index) { subtitleTrack in
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
                ForEach(viewModel.audioStreams.prepending(.none), id: \.index) { audioTrack in
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
                    Image(systemName: "speaker.wave.2")
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
                        if Float(speed.rawValue) == videoPlayerManager.playbackSpeed {
                            Label(speed.displayTitle, systemImage: "checkmark")
                        } else {
                            Text(speed.displayTitle)
                        }
                    }
                }
                
                if !PlaybackSpeed.allCases.map(\.rawValue).contains(where: { $0 == Double(videoPlayerManager.playbackSpeed) }) {
                    Label(videoPlayerManager.playbackSpeed.rateLabel, systemImage: "checkmark")
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
                overlayTimer.stop()
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
                splitContentViewProxy.present()
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
                if !viewModel.item.subtitleStreams.isEmpty {
                    subtitleTrackMenu
                }

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
