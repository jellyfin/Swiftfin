//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI
import VLCUI

extension VideoPlayer.Overlay {

    struct ActionButtons: View {

        // TODO: organize

        @Default(.VideoPlayer.showAudioTrackMenu)
        private var showAudioTrackMenu
        @Default(.VideoPlayer.showSubtitleTrackMenu)
        private var showSubtitleTrackMenu
        @Default(.VideoPlayer.showChapters)
        private var showChapters

        @Default(.VideoPlayer.showPlaybackSpeed)
        private var showPlaybackSpeed

        @Default(.VideoPlayer.showAspectFill)
        private var showAspectFill
        @Default(.VideoPlayer.autoPlay)
        private var autoPlay
        @Default(.VideoPlayer.autoPlayEnabled)
        private var autoPlayEnabled
        @Default(.VideoPlayer.playNextItem)
        private var playNextItem
        @Default(.VideoPlayer.playPreviousItem)
        private var playPreviousItem

        @Environment(\.aspectFilled)
        @Binding
        private var aspectFilled: Bool
        @Environment(\.currentOverlayType)
        @Binding
        private var currentOverlayType

        @EnvironmentObject
        private var overlayTimer: TimerProxy
        @EnvironmentObject
        private var videoPlayerManager: VideoPlayerManager
        @EnvironmentObject
        private var videoPlayerProxy: VLCVideoPlayer.Proxy
        @EnvironmentObject
        private var viewModel: VideoPlayerViewModel

        @ViewBuilder
        private var aspectFillButton: some View {
            Button {
                overlayTimer.start(5)
                if aspectFilled {
                    aspectFilled = false
                    UIView.animate(withDuration: 0.2) {
                        videoPlayerProxy.aspectFill(0)
                    }
                } else {
                    aspectFilled = true
                    UIView.animate(withDuration: 0.2) {
                        videoPlayerProxy.aspectFill(1)
                    }
                }
            } label: {
                Group {
                    if aspectFilled {
                        Image(systemName: "arrow.down.right.and.arrow.up.left")
                    } else {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                    }
                }
                .frame(width: 45, height: 45)
                .contentShape(Rectangle())
            }
        }

        @ViewBuilder
        private var autoPlayButton: some View {
            Button {
                autoPlayEnabled.toggle()
                overlayTimer.start(5)
            } label: {
                Group {
                    if autoPlayEnabled {
                        Image(systemName: "play.circle.fill")
                    } else {
                        Image(systemName: "stop.circle")
                    }
                }
                .frame(width: 45, height: 45)
                .contentShape(Rectangle())
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
                Group {
                    if videoPlayerManager.audioTrackIndex == -1 {
                        Image(systemName: "speaker.wave.2")
                    } else {
                        Image(systemName: "speaker.wave.2.fill")
                    }
                }
                .frame(width: 45, height: 45)
                .contentShape(Rectangle())
            }
        }

        @ViewBuilder
        private var chaptersButton: some View {
            Button {
                currentOverlayType = .chapters
                overlayTimer.stop()
            } label: {
                Image(systemName: "list.dash")
                    .frame(width: 45, height: 45)
                    .contentShape(Rectangle())
            }
        }

        @ViewBuilder
        private var nextItemButton: some View {
            Button {
                videoPlayerManager.selectNextViewModel()
                overlayTimer.start(5)
            } label: {
                Image(systemName: "chevron.right.circle")
                    .frame(width: 45, height: 45)
                    .contentShape(Rectangle())
            }
            .disabled(videoPlayerManager.nextViewModel == nil)
            .foregroundColor(videoPlayerManager.nextViewModel == nil ? .gray : .white)
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
                    Label(String(format: "%.2f", videoPlayerManager.playbackSpeed).appending("x"), systemImage: "checkmark")
                }
            } label: {
                Image(systemName: "speedometer")
                    .frame(width: 45, height: 45)
                    .contentShape(Rectangle())
            }
        }

        @ViewBuilder
        private var previousItemButton: some View {
            Button {
                videoPlayerManager.selectPreviousViewModel()
                overlayTimer.start(5)
            } label: {
                Image(systemName: "chevron.left.circle")
                    .frame(width: 45, height: 45)
                    .contentShape(Rectangle())
            }
            .disabled(videoPlayerManager.previousViewModel == nil)
            .foregroundColor(videoPlayerManager.previousViewModel == nil ? .gray : .white)
        }

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
                Group {
                    if videoPlayerManager.subtitleTrackIndex == -1 {
                        Image(systemName: "captions.bubble")
                    } else {
                        Image(systemName: "captions.bubble.fill")
                    }
                }
                .frame(width: 45, height: 45)
                .contentShape(Rectangle())
            }
        }

        var body: some View {
            HStack(spacing: 0) {
                if viewModel.item.type == .episode {

                    if playPreviousItem {
                        previousItemButton
                    }

                    if playNextItem {
                        nextItemButton
                    }

                    if autoPlay {
                        autoPlayButton
                    }
                }

                if showPlaybackSpeed {
                    playbackSpeedMenu
                }

                if showAudioTrackMenu {
                    audioTrackMenu
                }

                if showSubtitleTrackMenu {
                    subtitleTrackMenu
                }

                if showChapters {
                    chaptersButton
                }

                if showAspectFill {
                    aspectFillButton
                }

                OverlayMenu()
            }
        }
    }
}
