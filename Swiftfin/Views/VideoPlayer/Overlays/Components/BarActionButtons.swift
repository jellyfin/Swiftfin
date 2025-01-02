//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI
import VLCUI

extension VideoPlayer.Overlay {

    struct BarActionButtons: View {

        @Default(.VideoPlayer.barActionButtons)
        private var barActionButtons
        @Default(.VideoPlayer.menuActionButtons)
        private var menuActionButtons

        @EnvironmentObject
        private var viewModel: VideoPlayerViewModel

        @ViewBuilder
        private var advancedButton: some View {
            ActionButtons.Advanced {
                Image(systemName: "gearshape.fill")
                    .frame(width: 45, height: 45)
                    .contentShape(Rectangle())
            }
        }

        @ViewBuilder
        private var aspectFillButton: some View {
            ActionButtons.AspectFill { isAspectFilled in
                Group {
                    if isAspectFilled {
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
        private var audioTrackMenu: some View {
            ActionButtons.Audio { audioTrackSelected in
                Group {
                    if audioTrackSelected {
                        Image(systemName: "speaker.wave.2.fill")
                    } else {
                        Image(systemName: "speaker.wave.2")
                    }
                }
                .frame(width: 45, height: 45)
                .contentShape(Rectangle())
            }
        }

        @ViewBuilder
        private var autoPlayButton: some View {
            if viewModel.item.type == .episode {
                ActionButtons.AutoPlay { autoPlayEnabled in
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
        }

        @ViewBuilder
        private var chaptersButton: some View {
            if viewModel.chapters.isNotEmpty {
                ActionButtons.Chapters {
                    Image(systemName: "list.dash")
                        .frame(width: 45, height: 45)
                        .contentShape(Rectangle())
                }
            }
        }

        @ViewBuilder
        private var playbackSpeedMenu: some View {
            ActionButtons.PlaybackSpeedMenu {
                Image(systemName: "speedometer")
                    .frame(width: 45, height: 45)
                    .contentShape(Rectangle())
            }
        }

        @ViewBuilder
        private var playNextItemButton: some View {
            if viewModel.item.type == .episode {
                ActionButtons.PlayNextItem {
                    Image(systemName: "chevron.right.circle")
                        .frame(width: 45, height: 45)
                        .contentShape(Rectangle())
                }
            }
        }

        @ViewBuilder
        private var playPreviousItemButton: some View {
            if viewModel.item.type == .episode {
                ActionButtons.PlayPreviousItem {
                    Image(systemName: "chevron.left.circle")
                        .frame(width: 45, height: 45)
                        .contentShape(Rectangle())
                }
            }
        }

        @ViewBuilder
        private var subtitleTrackMenu: some View {
            ActionButtons.Subtitles { subtitleTrackSelected in
                Group {
                    if subtitleTrackSelected {
                        Image(systemName: "captions.bubble.fill")
                    } else {
                        Image(systemName: "captions.bubble")
                    }
                }
                .frame(width: 45, height: 45)
                .contentShape(Rectangle())
            }
        }

        var body: some View {
            HStack(spacing: 0) {
                ForEach(barActionButtons) { actionButton in
                    switch actionButton {
//                    case .advanced:
//                        advancedButton
                    case .aspectFill:
                        aspectFillButton
                    case .audio:
                        audioTrackMenu
                    case .autoPlay:
                        autoPlayButton
                    case .chapters:
                        chaptersButton
                    case .playbackSpeed:
                        playbackSpeedMenu
                    case .playNextItem:
                        playNextItemButton
                    case .playPreviousItem:
                        playPreviousItemButton
                    case .subtitles:
                        subtitleTrackMenu
                    }
                }

                if menuActionButtons.isNotEmpty {
                    OverlayMenu()
                }
            }
        }
    }
}
