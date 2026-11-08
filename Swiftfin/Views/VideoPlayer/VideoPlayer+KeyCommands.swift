//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

// TODO: protect against holding down

extension VideoPlayer {

    struct KeyCommandsModifier: ViewModifier {

        @Default(.VideoPlayer.jumpBackwardInterval)
        private var jumpBackwardInterval
        @Default(.VideoPlayer.jumpForwardInterval)
        private var jumpForwardInterval

        @Environment(ViewState.self)
        private var viewState

        @Environment(MediaSession.self)
        private var mediaSession

        @Toaster
        private var toaster: ToastProxy

        func body(content: Content) -> some View {
            content
                .keyCommands {

                    // MARK: Aspect Fill

                    KeyCommandAction(
                        title: "Aspect Fill",
                        input: "f",
                        modifierFlags: .command
                    ) { @MainActor in
                        viewState.toggleAspectFillBehavior()
                    }

                    KeyCommandAction(
                        title: L10n.playAndPause,
                        input: " "
                    ) {
                        guard mediaSession.canControlPlayback else { return }

                        mediaSession.togglePlayPause()

                        if !viewState.isPresentingControls {
                            if mediaSession.playbackRequestStatus == .paused {
                                toaster.present(
                                    L10n.pause,
                                    systemName: "pause.circle"
                                )
                            } else if mediaSession.playbackRequestStatus == .playing {
                                toaster.present(
                                    L10n.play,
                                    systemName: "play.circle"
                                )
                            }
                        }
                    }

                    // MARK: - Decrease Playback Speed

                    KeyCommandAction(
                        title: "Decrease Playback Speed",
                        input: "[",
                        modifierFlags: .command
                    ) {
                        let newRate = clamp(
                            mediaSession.rate - 0.25,
                            min: 0.25,
                            max: 4
                        )

                        mediaSession.rate = newRate

                        toaster.present(
                            Text(newRate, format: .playbackRate),
                            systemName: VideoPlayerActionButton.playbackSpeed.systemImage
                        )
                    }

                    // MARK: - Increase Playback Speed

                    KeyCommandAction(
                        title: "Increase Playback Speed",
                        input: "]",
                        modifierFlags: .command
                    ) {
                        let newRate = clamp(
                            mediaSession.rate + 0.25,
                            min: 0.25,
                            max: 4
                        )

                        mediaSession.rate = newRate

                        toaster.present(
                            Text(newRate, format: .playbackRate),
                            systemName: VideoPlayerActionButton.playbackSpeed.systemImage
                        )
                    }

                    // MARK: Reset Playback Speed

                    KeyCommandAction(
                        title: "Reset Playback Speed",
                        input: "\\",
                        modifierFlags: .command
                    ) {
                        mediaSession.rate = 1

                        toaster.present(
                            Text(1, format: .playbackRate),
                            systemName: VideoPlayerActionButton.playbackSpeed.systemImage
                        )
                    }

                    // MARK: Play Next Item

                    KeyCommandAction(
                        title: L10n.nextItem,
                        input: UIKeyCommand.inputRightArrow,
                        modifierFlags: .command
                    ) {
                        guard let nextItem = mediaSession.queue?.nextItem else { return }

                        mediaSession.playNewItem(intent: nextItem)
                    }

                    // MARK: Play Previous Item

                    KeyCommandAction(
                        title: L10n.previousItem,
                        input: UIKeyCommand.inputLeftArrow,
                        modifierFlags: .command
                    ) {
                        guard let previousItem = mediaSession.queue?.previousItem else { return }

                        mediaSession.playNewItem(intent: previousItem)
                    }

                    // MARK: - Jump Backward

                    KeyCommandAction(
                        title: L10n.jumpBackward,
                        input: UIKeyCommand.inputLeftArrow
                    ) {
                        guard mediaSession.canSeek else { return }

                        viewState.showProgress()
                        viewState.jumpProgressObserver.jumpBackward()
                        mediaSession.seek(by: .zero - (jumpBackwardInterval.rawValue))

                        toaster.present(
                            Text(
                                jumpBackwardInterval.rawValue * viewState.jumpProgressObserver.jumps,
                                format: .minuteSecondsAbbreviated
                            ),
                            systemName: "gobackward"
                        )
                    }

                    // MARK: - Jump Forward

                    KeyCommandAction(
                        title: L10n.jumpForward,
                        input: UIKeyCommand.inputRightArrow
                    ) {
                        guard mediaSession.canSeek else { return }

                        viewState.showProgress()
                        viewState.jumpProgressObserver.jumpForward()
                        mediaSession.seek(by: jumpForwardInterval.rawValue)

                        toaster.present(
                            Text(
                                jumpForwardInterval.rawValue * viewState.jumpProgressObserver.jumps,
                                format: .minuteSecondsAbbreviated
                            ),
                            systemName: "goforward"
                        )
                    }
                }
        }
    }
}
