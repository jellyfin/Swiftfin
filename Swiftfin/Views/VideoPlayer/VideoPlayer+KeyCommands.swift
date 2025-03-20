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

extension VideoPlayer {

    struct KeyCommandsModifier: ViewModifier {

        @Default(.VideoPlayer.jumpBackwardInterval)
        private var jumpBackwardInterval
        @Default(.VideoPlayer.jumpForwardInterval)
        private var jumpForwardInterval

        @Environment(\.isAspectFilled)
        @Binding
        private var isAspectFilled

        @EnvironmentObject
        private var jumpProgressObserver: JumpProgressObserver
        @EnvironmentObject
        private var toastProxy: ToastProxy
        @EnvironmentObject
        private var manager: MediaPlayerManager

        func body(content: Content) -> some View {
            content
                .keyCommands {

                    // MARK: Aspect Fill

                    KeyCommandAction(
                        title: "Aspect Fill",
                        input: "f",
                        modifierFlags: .command
                    ) { @MainActor in
                        isAspectFilled.toggle()
                    }

                    KeyCommandAction(
                        title: L10n.playAndPause,
                        input: " "
                    ) {
                        switch manager.playbackRequestStatus {
                        case .playing:
                            manager.proxy?.pause()
                        case .paused:
                            manager.proxy?.play()
                        }
                        //                if videoPlayerManager.state == .playing {
                        //                    videoPlayerManager.proxy?.pause()
                        //                    updateViewProxy.present(systemName: "pause.fill", title: "Pause")
                        //                } else {
                        //                    videoPlayerManager.proxy?.play()
                        //                    updateViewProxy.present(systemName: "play.fill", title: "Play")
                        //                }
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

                        manager.set(rate: newRate)

                        toastProxy.present(Text(newRate, format: .playbackRate), systemName: "speedometer")
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

                        manager.set(rate: newRate)

                        toastProxy.present(Text(newRate, format: .playbackRate), systemName: "speedometer")
                    }

                    // MARK: Reset Playback Speed

                    KeyCommandAction(
                        title: "Reset Playback Speed",
                        input: "\\",
                        modifierFlags: .command
                    ) {
                        manager.set(rate: 1)
                        toastProxy.present(Text(1, format: .playbackRate), systemName: "speedometer")
                    }

                    // MARK: Play Next Item

                    KeyCommandAction(
                        title: L10n.nextItem,
                        input: UIKeyCommand.inputRightArrow,
                        modifierFlags: .command
                    ) {
                        guard let nextItem = manager.queue?.nextItem else { return }
                        manager.send(.playNew(item: nextItem))
                    }

                    // MARK: Play Previous Item

                    KeyCommandAction(
                        title: L10n.previousItem,
                        input: UIKeyCommand.inputLeftArrow,
                        modifierFlags: .command
                    ) {
                        guard let previousItem = manager.queue?.previousItem else { return }
                        manager.send(.playNew(item: previousItem))
                    }

                    // MARK: - Jump Backward

                    KeyCommandAction(
                        title: L10n.jumpBackward,
                        input: UIKeyCommand.inputLeftArrow
                    ) {
                        jumpProgressObserver.jumpBackward()
                        manager.proxy?.jumpBackward(jumpBackwardInterval.interval)

                        toastProxy.present(
                            Text(Double(jumpProgressObserver.jumps) * jumpBackwardInterval.interval, format: .minuteSeconds),
                            systemName: "gobackward"
                        )
                    }

                    // MARK: - Jump Forward

                    KeyCommandAction(
                        title: L10n.jumpForward,
                        input: UIKeyCommand.inputRightArrow
                    ) {
                        jumpProgressObserver.jumpForward()
                        manager.proxy?.jumpForward(jumpForwardInterval.interval)

                        toastProxy.present(
                            Text(Double(jumpProgressObserver.jumps) * jumpForwardInterval.interval, format: .minuteSeconds),
                            systemName: "goforward"
                        )
                    }
                }
        }
    }
}
