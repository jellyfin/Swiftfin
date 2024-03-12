//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import PreferencesView
import SwiftUI

extension View {

    func videoPlayerKeyCommands(
        isAspectFilled: Binding<Bool>,
        gestureStateHandler: VideoPlayer.GestureStateHandler,
        videoPlayerManager: VideoPlayerManager,
        updateViewProxy: UpdateViewProxy
    ) -> some View {
        keyCommands {

            // MARK: play/pause

            KeyCommandAction(
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

            // MARK: jump forward

            KeyCommandAction(
                title: L10n.jumpForward,
                input: UIKeyCommand.inputRightArrow
            ) {
                if gestureStateHandler.jumpForwardKeyPressActive {
                    gestureStateHandler.jumpForwardKeyPressAmount += 1
                    gestureStateHandler.jumpForwardKeyPressWorkItem?.cancel()
                    
//                    videoPlayerProxy.jumpBackward(Int(jumpBackwardLength.rawValue))

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
            }

            // MARK: jump backward

            KeyCommandAction(
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
            }

            // MARK: aspect fill

            KeyCommandAction(
                title: "Aspect Fill",
                input: "f",
                modifierFlags: .command
            ) {
                DispatchQueue.main.async {
                    isAspectFilled.wrappedValue.toggle()
                }
            }

            // MARK: Decrease Playback Speed

            KeyCommandAction(
                title: "Decrease Playback Speed",
                input: "[",
                modifierFlags: .command
            ) {
                let clampedPlaybackSpeed = clamp(
                    videoPlayerManager.playbackSpeed.rawValue - 0.25,
                    min: 0.25,
                    max: 2.0
                )

                let newPlaybackSpeed = PlaybackSpeed(rawValue: clampedPlaybackSpeed) ?? .one
                videoPlayerManager.playbackSpeed = newPlaybackSpeed
                videoPlayerManager.proxy.setRate(.absolute(Float(newPlaybackSpeed.rawValue)))

                updateViewProxy.present(systemName: "speedometer", title: newPlaybackSpeed.rawValue.rateLabel)
            }

            KeyCommandAction(
                title: "Increase Playback Speed",
                input: "]",
                modifierFlags: .command
            ) {
                let clampedPlaybackSpeed = clamp(
                    videoPlayerManager.playbackSpeed.rawValue + 0.25,
                    min: 0.25,
                    max: 2.0
                )

                let newPlaybackSpeed = PlaybackSpeed(rawValue: clampedPlaybackSpeed) ?? .one
                videoPlayerManager.playbackSpeed = newPlaybackSpeed
                videoPlayerManager.proxy.setRate(.absolute(Float(newPlaybackSpeed.rawValue)))

                updateViewProxy.present(systemName: "speedometer", title: newPlaybackSpeed.rawValue.rateLabel)
            }

            KeyCommandAction(
                title: "Reset Playback Speed",
                input: "\\",
                modifierFlags: .command
            ) {
                let newPlaybackSpeed = PlaybackSpeed.one
                
                videoPlayerManager.playbackSpeed = newPlaybackSpeed
                videoPlayerManager.proxy.setRate(.absolute(Float(newPlaybackSpeed.rawValue)))

                updateViewProxy.present(systemName: "speedometer", title: newPlaybackSpeed.rawValue.rateLabel)
            }

            KeyCommandAction(
                title: L10n.nextItem,
                input: UIKeyCommand.inputRightArrow,
                modifierFlags: .command
            ) {
                videoPlayerManager.selectNextViewModel()
            }

            KeyCommandAction(
                title: L10n.previousItem,
                input: UIKeyCommand.inputLeftArrow,
                modifierFlags: .command
            ) {
                videoPlayerManager.selectPreviousViewModel()
            }
        }
    }
}
