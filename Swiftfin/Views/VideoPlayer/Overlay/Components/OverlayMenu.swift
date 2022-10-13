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
        private var viewModel: ItemVideoPlayerViewModel
        @EnvironmentObject
        private var videoPlayerProxy: VLCVideoPlayer.Proxy

        @ViewBuilder
        private var subtitleTrackMenu: some View {
            Menu {
                ForEach(viewModel.subtitleStreams, id: \.self) { subtitleStream in
                    Button {
                        videoPlayerProxy.setSubtitleTrack(.absolute(subtitleStream.index ?? -1))
                    } label: {
                        Text(subtitleStream.displayTitle ?? .emptyDash)
                    }
                    
//                    Button {
//                        vlcVideoPlayerProxy.setSubtitleTrack(.absolute(subtitleStreamIndex))
//                    } label: {
//                        if subtitleStreamIndex == viewModel.selectedSubtitleTrackIndex {
//                            Label(viewModel.playerSubtitleTracks[subtitleStreamIndex] ?? L10n.noTitle, systemImage: "checkmark")
//                        } else {
//                            Text(viewModel.playerSubtitleTracks[subtitleStreamIndex] ?? L10n.noTitle)
//                        }
//                    }
                }
            } label: {
                HStack {
                    Image(systemName: "captions.bubble")
                    L10n.subtitles.text
                }
            }
        }

//        @ViewBuilder
//        private var audioTrackMenu: some View {
//            Menu {
//                ForEach(viewModel.playerAudioTracks.keys.sorted(), id: \.self) { audioStreamIndex in
//                    Button {
//                        vlcVideoPlayerProxy.setAudioTrack(.absolute(audioStreamIndex))
//                    } label: {
//                        Text(viewModel.playerAudioTracks[audioStreamIndex] ?? L10n.noTitle)
//                    }
//                }
//            } label: {
//                HStack {
//                    Image(systemName: "speaker.wave.3")
//                    L10n.audio.text
//                }
//            }
//        }
//
//        @ViewBuilder
//        private var playbackSpeedMenu: some View {
//            Menu {
//                ForEach(PlaybackSpeed.allCases, id: \.self) { speed in
//                    Button {
//                        vlcVideoPlayerProxy.setRate(.absolute(Float(speed.rawValue)))
//                        viewModel.playerPlaybackSpeed = speed
//                    } label: {
//                        if speed == viewModel.playerPlaybackSpeed {
//                            Label(speed.displayTitle, systemImage: "checkmark")
//                        } else {
//                            Text(speed.displayTitle)
//                        }
//                    }
//                }
//            } label: {
//                HStack {
//                    Image(systemName: "speedometer")
//                    L10n.playbackSpeed.text
//                }
//            }
//        }

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

//                audioTrackMenu
//
//                playbackSpeedMenu

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
