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
                
                // MARK: Aspect Fille

                KeyCommandAction(
                    title: "Aspect Fill",
                    input: "f",
                    modifierFlags: .command
                ) {
                    DispatchQueue.main.async {
                        isAspectFilled.toggle()
                    }
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
            }
        }
    }
}

// MARK: - OLD

struct VideoPlayerKeyCommandsModifier: ViewModifier {

    @Default(.VideoPlayer.jumpBackwardInterval)
    private var jumpBackwardInterval
    @Default(.VideoPlayer.jumpForwardInterval)
    private var jumpForwardInterval

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
        }
    }
}
