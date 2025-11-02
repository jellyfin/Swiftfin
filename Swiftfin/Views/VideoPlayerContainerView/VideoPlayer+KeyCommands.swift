//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import PreferencesView
import SwiftUI
import VLCUI

// TODO: protect against holding down

extension VideoPlayer {

    struct KeyCommandsModifier: ViewModifier {

        @Default(.VideoPlayer.jumpBackwardInterval)
        private var jumpBackwardInterval
        @Default(.VideoPlayer.jumpForwardInterval)
        private var jumpForwardInterval

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState

        @EnvironmentObject
        private var manager: MediaPlayerManager

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
                        containerState.isAspectFilled.toggle()
                    }

                    KeyCommandAction(
                        title: L10n.playAndPause,
                        input: " "
                    ) {
                        manager.togglePlayPause()

                        if !containerState.isPresentingOverlay {
                            if manager.playbackRequestStatus == .paused {
                                toaster.present(
                                    L10n.pause,
                                    systemName: "pause.circle"
                                )
                            } else if manager.playbackRequestStatus == .playing {
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
                            manager.rate - 0.25,
                            min: 0.25,
                            max: 4
                        )

                        manager.setRate(rate: newRate)

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
                            manager.rate + 0.25,
                            min: 0.25,
                            max: 4
                        )

                        manager.setRate(rate: newRate)

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
                        manager.setRate(rate: 1)
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
                        guard let nextItem = manager.queue?.nextItem else { return }
                        manager.playNewItem(provider: nextItem)
                    }

                    // MARK: Play Previous Item

                    KeyCommandAction(
                        title: L10n.previousItem,
                        input: UIKeyCommand.inputLeftArrow,
                        modifierFlags: .command
                    ) {
                        guard let previousItem = manager.queue?.previousItem else { return }
                        manager.playNewItem(provider: previousItem)
                    }

                    // MARK: - Jump Backward

                    KeyCommandAction(
                        title: L10n.jumpBackward,
                        input: UIKeyCommand.inputLeftArrow
                    ) {
                        containerState.jumpProgressObserver.jumpBackward()
                        manager.proxy?.jumpBackward(jumpBackwardInterval.rawValue)

                        toaster.present(
                            Text(
                                jumpBackwardInterval.rawValue * containerState.jumpProgressObserver.jumps,
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
                        containerState.jumpProgressObserver.jumpForward()
                        manager.proxy?.jumpForward(jumpForwardInterval.rawValue)

                        toaster.present(
                            Text(
                                jumpForwardInterval.rawValue * containerState.jumpProgressObserver.jumps,
                                format: .minuteSecondsAbbreviated
                            ),
                            systemName: "goforward"
                        )
                    }
                }
        }
    }
}
