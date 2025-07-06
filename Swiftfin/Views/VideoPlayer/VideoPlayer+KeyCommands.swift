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

extension View {

    func videoPlayerKeyCommands(
        gestureStateHandler: VideoPlayer.GestureStateHandler,
        updateViewProxy: UpdateViewProxy
    ) -> some View {
        modifier(
            VideoPlayerKeyCommandsModifier(
                gestureStateHandler: gestureStateHandler,
                updateViewProxy: updateViewProxy
            )
        )
    }
}

struct VideoPlayerKeyCommandsModifier: ViewModifier {

    @Default(.VideoPlayer.jumpBackwardLength)
    private var jumpBackwardLength
    @Default(.VideoPlayer.jumpForwardLength)
    private var jumpForwardLength

    @Environment(\.aspectFilled)
    private var isAspectFilled

    @EnvironmentObject
    private var videoPlayerManager: VideoPlayerManager
    @EnvironmentObject
    private var videoPlayerProxy: VLCVideoPlayer.Proxy

    let gestureStateHandler: VideoPlayer.GestureStateHandler
    let updateViewProxy: UpdateViewProxy

    func body(content: Content) -> some View {
        content.keyCommands {

            // MARK: play/pause

            KeyCommandAction(
                title: L10n.playAndPause,
                input: " "
            ) {
                Task { @MainActor in
                    if videoPlayerManager.state == .playing {
                        videoPlayerManager.proxy.pause()
                        updateViewProxy.present(systemName: "pause.fill", title: L10n.pause)
                    } else {
                        videoPlayerManager.proxy.play()
                        updateViewProxy.present(systemName: "play.fill", title: L10n.play)
                    }
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

                    Task { @MainActor in
                        videoPlayerProxy.jumpForward(Int(jumpForwardLength.rawValue))
                    }

                    let task = DispatchWorkItem {
                        gestureStateHandler.jumpForwardKeyPressActive = false
                        gestureStateHandler.jumpForwardKeyPressAmount = 0
                    }

                    gestureStateHandler.jumpForwardKeyPressWorkItem = task

                    DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: task)
                } else {
                    gestureStateHandler.jumpForwardKeyPressActive = true
                    gestureStateHandler.jumpForwardKeyPressAmount += 1

                    videoPlayerProxy.jumpForward(Int(jumpForwardLength.rawValue))

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

                    videoPlayerProxy.jumpBackward(Int(jumpBackwardLength.rawValue))

                    let task = DispatchWorkItem {
                        gestureStateHandler.jumpBackwardKeyPressActive = false
                        gestureStateHandler.jumpBackwardKeyPressAmount = 0
                    }

                    gestureStateHandler.jumpBackwardKeyPressWorkItem = task

                    DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: task)
                } else {
                    gestureStateHandler.jumpBackwardKeyPressActive = true
                    gestureStateHandler.jumpBackwardKeyPressAmount += 1

                    videoPlayerProxy.jumpBackward(Int(jumpBackwardLength.rawValue))

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
                title: L10n.aspectFill,
                input: "f",
                modifierFlags: .command
            ) {
                DispatchQueue.main.async {
                    isAspectFilled.wrappedValue.toggle()
                }
            }

            // MARK: decrease playback speed

            KeyCommandAction(
                title: L10n.decreasePlaybackSpeed,
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

            // MARK: increase playback speed

            KeyCommandAction(
                title: L10n.increasePlaybackSpeed,
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

            // MARK: reset playback speed

            KeyCommandAction(
                title: L10n.resetPlaybackSpeed,
                input: "\\",
                modifierFlags: .command
            ) {
                let newPlaybackSpeed = PlaybackSpeed.one

                videoPlayerManager.playbackSpeed = newPlaybackSpeed
                videoPlayerManager.proxy.setRate(.absolute(Float(newPlaybackSpeed.rawValue)))

                updateViewProxy.present(systemName: "speedometer", title: newPlaybackSpeed.rawValue.rateLabel)
            }

            // MARK: next item

            KeyCommandAction(
                title: L10n.nextItem,
                input: UIKeyCommand.inputRightArrow,
                modifierFlags: .command
            ) {
                videoPlayerManager.selectNextViewModel()
            }

            // MARK: previous item

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
