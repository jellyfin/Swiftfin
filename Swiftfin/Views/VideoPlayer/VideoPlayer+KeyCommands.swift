//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import PreferencesView
import SwiftUI
import VLCUI

extension VideoPlayer {

    struct KeyCommandsLayer: View {

        @Default(.VideoPlayer.jumpBackwardInterval)
        private var jumpBackwardInterval
        @Default(.VideoPlayer.jumpForwardInterval)
        private var jumpForwardInterval

        @Environment(\.isAspectFilled)
        @Binding
        private var isAspectFilled

        @EnvironmentObject
        private var toastProxy: ToastProxy
        @EnvironmentObject
        private var manager: MediaPlayerManager

        var body: some View {
            keyCommands {

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
                    
                    toastProxy.present(Text(newRate, format: .rate), systemName: "speedometer")
                }
            }
        }
    }
}

struct VideoPlayerKeyCommandsModifier: ViewModifier {

    @Default(.VideoPlayer.jumpBackwardInterval)
    private var jumpBackwardInterval
    @Default(.VideoPlayer.jumpForwardInterval)
    private var jumpForwardInterval

    @Environment(\.isAspectFilled)
    @Binding
    private var isAspectFilled

    @EnvironmentObject
    private var manager: MediaPlayerManager
    @EnvironmentObject
    private var toastProxy: ToastProxy

    func body(content: Content) -> some View {
        content.keyCommands {

            // MARK: jump forward

            KeyCommandAction(
                title: L10n.jumpForward,
                input: UIKeyCommand.inputRightArrow
            ) {
//                if gestureStateHandler.jumpForwardKeyPressActive {
//                    gestureStateHandler.jumpForwardKeyPressAmount += 1
//                    gestureStateHandler.jumpForwardKeyPressWorkItem?.cancel()
//
//                    videoPlayerProxy.jumpForward(Int(jumpForwardLength.rawValue))
//
//                    let task = DispatchWorkItem {
//                        gestureStateHandler.jumpForwardKeyPressActive = false
//                        gestureStateHandler.jumpForwardKeyPressAmount = 0
//                    }
//
//                    gestureStateHandler.jumpForwardKeyPressWorkItem = task
//
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: task)
//                } else {
//                    gestureStateHandler.jumpForwardKeyPressActive = true
//                    gestureStateHandler.jumpForwardKeyPressAmount += 1
//
//                    videoPlayerProxy.jumpForward(Int(jumpForwardLength.rawValue))
//
//                    let task = DispatchWorkItem {
//                        gestureStateHandler.jumpForwardKeyPressActive = false
//                        gestureStateHandler.jumpForwardKeyPressAmount = 0
//                    }
//
//                    gestureStateHandler.jumpForwardKeyPressWorkItem = task
//
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: task)
//                }
            }

            // MARK: jump backward

            KeyCommandAction(
                title: L10n.jumpBackward,
                input: UIKeyCommand.inputLeftArrow
            ) {
//                if gestureStateHandler.jumpBackwardKeyPressActive {
//                    gestureStateHandler.jumpBackwardKeyPressAmount += 1
//                    gestureStateHandler.jumpBackwardKeyPressWorkItem?.cancel()
//
//                    videoPlayerProxy.jumpBackward(Int(jumpBackwardLength.rawValue))
//
//                    let task = DispatchWorkItem {
//                        gestureStateHandler.jumpBackwardKeyPressActive = false
//                        gestureStateHandler.jumpBackwardKeyPressAmount = 0
//                    }
//
//                    gestureStateHandler.jumpBackwardKeyPressWorkItem = task
//
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: task)
//                } else {
//                    gestureStateHandler.jumpBackwardKeyPressActive = true
//                    gestureStateHandler.jumpBackwardKeyPressAmount += 1
//
//                    videoPlayerProxy.jumpBackward(Int(jumpBackwardLength.rawValue))
//
//                    let task = DispatchWorkItem {
//                        gestureStateHandler.jumpBackwardKeyPressActive = false
//                        gestureStateHandler.jumpBackwardKeyPressAmount = 0
//                    }
//
//                    gestureStateHandler.jumpBackwardKeyPressWorkItem = task
//
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: task)
//                }
            }

            // MARK: aspect fill

            KeyCommandAction(
                title: "Aspect Fill",
                input: "f",
                modifierFlags: .command
            ) {
                DispatchQueue.main.async {
                    isAspectFilled.toggle()
                }
            }

            // MARK: decrease playback speed

            KeyCommandAction(
                title: "Decrease Playback Speed",
                input: "[",
                modifierFlags: .command
            ) {
                
//                let clampedPlaybackSpeed = clamp(
//                    videoPlayerManager.playbackRate.rate - 0.25,
//                    min: 0.25,
//                    max: 2.0
//                )

//                let newPlaybackSpeed = PlaybackSpeed(rawValue: clampedPlaybackSpeed) ?? .one
//                videoPlayerManager.playbackSpeed = newPlaybackSpeed
//                videoPlayerManager.proxy.setRate(Float(newPlaybackSpeed.rawValue))

//                updateViewProxy.present(systemName: "speedometer", title: newPlaybackSpeed.rawValue.rateLabel)
            }

            // MARK: increase playback speed

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
                
                toastProxy.present(Text(newRate, format: .rate), systemName: "speedometer")
                
//                let clampedPlaybackSpeed = clamp(
//                    videoPlayerManager.playbackSpeed.rawValue + 0.25,
//                    min: 0.25,
//                    max: 2.0
//                )

//                let newPlaybackSpeed = PlaybackSpeed(rawValue: clampedPlaybackSpeed) ?? .one
//                videoPlayerManager.playbackSpeed = newPlaybackSpeed
//                videoPlayerManager.proxy.setRate(Float(newPlaybackSpeed.rawValue))

//                updateViewProxy.present(systemName: "speedometer", title: newPlaybackSpeed.rawValue.rateLabel)
            }

            // MARK: reset playback speed

            KeyCommandAction(
                title: "Reset Playback Speed",
                input: "\\",
                modifierFlags: .command
            ) {
//                let newPlaybackSpeed = PlaybackSpeed.one

//                videoPlayerManager.playbackSpeed = newPlaybackSpeed
//                videoPlayerManager.proxy.setRate(Float(newPlaybackSpeed.rawValue))

//                updateViewProxy.present(systemName: "speedometer", title: newPlaybackSpeed.rawValue.rateLabel)
            }

            // MARK: next item

            KeyCommandAction(
                title: L10n.nextItem,
                input: UIKeyCommand.inputRightArrow,
                modifierFlags: .command
            ) {
//                videoPlayerManager.selectNextViewModel()
            }

            // MARK: previous item

            KeyCommandAction(
                title: L10n.previousItem,
                input: UIKeyCommand.inputLeftArrow,
                modifierFlags: .command
            ) {
//                videoPlayerManager.selectPreviousViewModel()
            }
        }
    }
}
