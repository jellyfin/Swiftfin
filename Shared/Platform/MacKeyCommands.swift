//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

#if os(macOS)
import Defaults
import SwiftUI

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

        func body(content: Content) -> some View {
            content
                .background {
                    ZStack {
                        Button {
                            containerState.isAspectFilled.toggle()
                        } label: {
                            EmptyView()
                        }
                        .keyboardShortcut("f", modifiers: .command)

                        Button {
                            manager.togglePlayPause()
                        } label: {
                            EmptyView()
                        }
                        .keyboardShortcut(.space, modifiers: [])

                        Button {
                            manager.setRate(rate: clamp(manager.rate - 0.25, min: 0.25, max: 4))
                        } label: {
                            EmptyView()
                        }
                        .keyboardShortcut(KeyEquivalent("["), modifiers: .command)

                        Button {
                            manager.setRate(rate: clamp(manager.rate + 0.25, min: 0.25, max: 4))
                        } label: {
                            EmptyView()
                        }
                        .keyboardShortcut(KeyEquivalent("]"), modifiers: .command)

                        Button {
                            manager.setRate(rate: 1)
                        } label: {
                            EmptyView()
                        }
                        .keyboardShortcut(KeyEquivalent("\\"), modifiers: .command)

                        Button {
                            guard let nextItem = manager.queue?.nextItem else { return }
                            manager.playNewItem(provider: nextItem)
                        } label: {
                            EmptyView()
                        }
                        .keyboardShortcut(.rightArrow, modifiers: .command)

                        Button {
                            guard let previousItem = manager.queue?.previousItem else { return }
                            manager.playNewItem(provider: previousItem)
                        } label: {
                            EmptyView()
                        }
                        .keyboardShortcut(.leftArrow, modifiers: .command)

                        Button {
                            containerState.jumpProgressObserver.jumpBackward()
                            manager.proxy?.jumpBackward(jumpBackwardInterval.rawValue)
                        } label: {
                            EmptyView()
                        }
                        .keyboardShortcut(.leftArrow, modifiers: [])

                        Button {
                            containerState.jumpProgressObserver.jumpForward()
                            manager.proxy?.jumpForward(jumpForwardInterval.rawValue)
                        } label: {
                            EmptyView()
                        }
                        .keyboardShortcut(.rightArrow, modifiers: [])
                    }
                    .frame(width: 0, height: 0)
                    .opacity(0)
                }
        }
    }
}
#endif
