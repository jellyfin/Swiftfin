//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ItemVideoPlayer.Overlay {

    struct OverlayMenu: View {

        @EnvironmentObject
        private var viewModel: ItemVideoPlayerViewModel
        @EnvironmentObject
        private var overlayTimer: TimerProxy
        @Environment(\.currentOverlayType)
        @Binding
        private var currentOverlayType
        @Environment(\.showAdvancedSettings)
        @Binding
        private var showAdvancedSettings

        @ViewBuilder
        private var subtitleTrackMenu: some View {
            Menu {
                ForEach(viewModel.playerSubtitleTracks.keys.sorted(), id: \.self) { subtitleStreamIndex in
                    Button {
                        viewModel.proxy.setSubtitleTrack(.absolute(subtitleStreamIndex))
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
        }

        @ViewBuilder
        private var audioTrackMenu: some View {
            Menu {
                ForEach(viewModel.playerAudioTracks.keys.sorted(), id: \.self) { audioStreamIndex in
                    Button {
                        viewModel.proxy.setAudioTrack(.absolute(audioStreamIndex))
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
        }

        @ViewBuilder
        private var playbackSpeedMenu: some View {
            Menu {
                ForEach(PlaybackSpeed.allCases, id: \.self) { speed in
                    Button {
                        viewModel.proxy.setRate(.absolute(Float(speed.rawValue)))
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
                showAdvancedSettings = true
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
