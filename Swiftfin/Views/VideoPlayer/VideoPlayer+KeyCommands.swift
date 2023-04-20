//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension View {

    func videoPlayerKeyCommands(
        gestureStateHandler: VideoPlayer.GestureStateHandler,
        videoPlayerManager: VideoPlayerManager,
        updateViewProxy: UpdateViewProxy
    ) -> some View {
        self
            .addingKeyCommand(
                title: L10n.playAndPause,
                input: " "
            ) {
                if videoPlayerManager.state == .playing {
                    videoPlayerManager.proxy.pause()
                    updateViewProxy.present(systemName: "pause.fill", title: "Pause")
                } else {
                    videoPlayerManager.proxy.play()
                    updateViewProxy.present(systemName: "play.fill", title: "Play")
                }
            }
            .addingKeyCommand(
                title: L10n.jumpForward,
                input: UIKeyCommand.inputRightArrow
            ) {
                if gestureStateHandler.jumpForwardKeyPressActive {
                    gestureStateHandler.jumpForwardKeyPressAmount += 1
                    gestureStateHandler.jumpForwardKeyPressWorkItem?.cancel()

                    let task = DispatchWorkItem {
                        gestureStateHandler.jumpForwardKeyPressActive = false
                        gestureStateHandler.jumpForwardKeyPressAmount = 0
                    }

                    gestureStateHandler.jumpForwardKeyPressWorkItem = task

                    DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: task)
                } else {
                    gestureStateHandler.jumpForwardKeyPressActive = true
                    gestureStateHandler.jumpForwardKeyPressAmount += 1

                    let task = DispatchWorkItem {
                        gestureStateHandler.jumpForwardKeyPressActive = false
                        gestureStateHandler.jumpForwardKeyPressAmount = 0
                    }

                    gestureStateHandler.jumpForwardKeyPressWorkItem = task

                    DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: task)
                }

//                    jumpAction(unitPoint: .init(x: 1, y: 0), amount: gestureStateHandler.jumpForwardKeyPressAmount)
            }
            .addingKeyCommand(
                title: L10n.jumpBackward,
                input: UIKeyCommand.inputLeftArrow
            ) {
                if gestureStateHandler.jumpBackwardKeyPressActive {
                    gestureStateHandler.jumpBackwardKeyPressAmount += 1
                    gestureStateHandler.jumpBackwardKeyPressWorkItem?.cancel()

                    let task = DispatchWorkItem {
                        gestureStateHandler.jumpBackwardKeyPressActive = false
                        gestureStateHandler.jumpBackwardKeyPressAmount = 0
                    }

                    gestureStateHandler.jumpBackwardKeyPressWorkItem = task

                    DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: task)
                } else {
                    gestureStateHandler.jumpBackwardKeyPressActive = true
                    gestureStateHandler.jumpBackwardKeyPressAmount += 1

                    let task = DispatchWorkItem {
                        gestureStateHandler.jumpBackwardKeyPressActive = false
                        gestureStateHandler.jumpBackwardKeyPressAmount = 0
                    }

                    gestureStateHandler.jumpBackwardKeyPressWorkItem = task

                    DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: task)
                }

//                    jumpAction(unitPoint: .init(x: 0, y: 0), amount: gestureStateHandler.jumpBackwardKeyPressAmount)
            }

//        self.keyCommands([
//            .init(
//                title: L10n.playAndPause,
//                input: " ",
//                action: {
//                    if videoPlayerManager.state == .playing {
//                        videoPlayerManager.proxy.pause()
//                        updateViewProxy.present(systemName: "pause.fill", title: "Pause")
//                    } else {
//                        videoPlayerManager.proxy.play()
//                        updateViewProxy.present(systemName: "play.fill", title: "Play")
//                    }
//                }
//            ),
//            .init(
//                title: L10n.jumpForward,
//                input: UIKeyCommand.inputRightArrow,
//                action: {
//                    if gestureStateHandler.jumpForwardKeyPressActive {
//                        gestureStateHandler.jumpForwardKeyPressAmount += 1
//                        gestureStateHandler.jumpForwardKeyPressWorkItem?.cancel()
//
//                        let task = DispatchWorkItem {
//                            gestureStateHandler.jumpForwardKeyPressActive = false
//                            gestureStateHandler.jumpForwardKeyPressAmount = 0
//                        }
//
//                        gestureStateHandler.jumpForwardKeyPressWorkItem = task
//
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: task)
//                    } else {
//                        gestureStateHandler.jumpForwardKeyPressActive = true
//                        gestureStateHandler.jumpForwardKeyPressAmount += 1
//
//                        let task = DispatchWorkItem {
//                            gestureStateHandler.jumpForwardKeyPressActive = false
//                            gestureStateHandler.jumpForwardKeyPressAmount = 0
//                        }
//
//                        gestureStateHandler.jumpForwardKeyPressWorkItem = task
//
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: task)
//                    }
//
        ////                    jumpAction(unitPoint: .init(x: 1, y: 0), amount: gestureStateHandler.jumpForwardKeyPressAmount)
//                }
//            ),
//            .init(
//                title: L10n.jumpBackward,
//                input: UIKeyCommand.inputLeftArrow,
//                action: {
//                    if gestureStateHandler.jumpBackwardKeyPressActive {
//                        gestureStateHandler.jumpBackwardKeyPressAmount += 1
//                        gestureStateHandler.jumpBackwardKeyPressWorkItem?.cancel()
//
//                        let task = DispatchWorkItem {
//                            gestureStateHandler.jumpBackwardKeyPressActive = false
//                            gestureStateHandler.jumpBackwardKeyPressAmount = 0
//                        }
//
//                        gestureStateHandler.jumpBackwardKeyPressWorkItem = task
//
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: task)
//                    } else {
//                        gestureStateHandler.jumpBackwardKeyPressActive = true
//                        gestureStateHandler.jumpBackwardKeyPressAmount += 1
//
//                        let task = DispatchWorkItem {
//                            gestureStateHandler.jumpBackwardKeyPressActive = false
//                            gestureStateHandler.jumpBackwardKeyPressAmount = 0
//                        }
//
//                        gestureStateHandler.jumpBackwardKeyPressWorkItem = task
//
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: task)
//                    }
//
        ////                    jumpAction(unitPoint: .init(x: 0, y: 0), amount: gestureStateHandler.jumpBackwardKeyPressAmount)
//                }
//            ),
//            .init(
//                title: "Decrease Playback Speed",
//                input: "[",
//                modifierFlags: .command,
//                action: {
//                    let clampedPlaybackSpeed = clamp(
//                        videoPlayerManager.playbackSpeed - 0.25,
//                        min: 0.25,
//                        max: 5.0
//                    )
//
//                    updateViewProxy.present(systemName: "speedometer", title: clampedPlaybackSpeed.rateLabel)
//                    videoPlayerManager.proxy.setRate(.absolute(clampedPlaybackSpeed))
//                }
//            ),
//            .init(
//                title: "Increase Playback Speed",
//                input: "]",
//                modifierFlags: .command,
//                action: {
//                    let clampedPlaybackSpeed = clamp(
//                        videoPlayerManager.playbackSpeed + 0.25,
//                        min: 0.25,
//                        max: 5.0
//                    )
//
//                    updateViewProxy.present(systemName: "speedometer", title: clampedPlaybackSpeed.rateLabel)
//                    videoPlayerManager.proxy.setRate(.absolute(clampedPlaybackSpeed))
//                }
//            ),
//            .init(
//                title: "Reset Playback Speed",
//                input: "\\",
//                modifierFlags: .command,
//                action: {
//                    let clampedPlaybackSpeed: Float = 1
//
//                    updateViewProxy.present(systemName: "speedometer", title: clampedPlaybackSpeed.rateLabel)
//                    videoPlayerManager.proxy.setRate(.absolute(clampedPlaybackSpeed))
//                }
//            ),
//            .init(
//                title: L10n.nextItem,
//                input: UIKeyCommand.inputRightArrow,
//                modifierFlags: .command,
//                action: {
//                    videoPlayerManager.selectNextViewModel()
//                }
//            ),
//            .init(
//                title: L10n.nextItem,
//                input: UIKeyCommand.inputLeftArrow,
//                modifierFlags: .command,
//                action: {
//                    videoPlayerManager.selectPreviousViewModel()
//                }
//            ),
//        ])
    }
}
