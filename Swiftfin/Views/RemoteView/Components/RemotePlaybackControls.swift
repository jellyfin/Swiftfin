//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

extension RemoteView {

    struct PlaybackControls<Proxy: RemoteMediaPlayerProxy & MediaPlayerQueueConfigurable>: View {

        @Default(.VideoPlayer.jumpBackwardInterval)
        private var jumpBackwardInterval
        @Default(.VideoPlayer.jumpForwardInterval)
        private var jumpForwardInterval

        @ObservedObject
        private var proxy: Proxy

        private let onChannelDown: (() -> Void)?
        private let onChannelUp: (() -> Void)?

        init(
            proxy: Proxy,
            onChannelUp: (() -> Void)? = nil,
            onChannelDown: (() -> Void)? = nil
        ) {
            self.proxy = proxy
            self.onChannelUp = onChannelUp
            self.onChannelDown = onChannelDown
        }

        private var hasQueue: Bool {
            proxy.queueCount > 1
        }

        private var isLive: Bool {
            proxy.activeItem?.isLiveContent == true
        }

        var body: some View {
            HStack(spacing: 24) {
                if hasQueue {
                    Button(L10n.playPreviousItem, systemImage: "backward.end.fill") {
                        proxy.previousItem()
                    }
                    .buttonStyle(.remoteControl(size: .small))
                    .disabled(proxy.queueItems.startIndex == proxy.queueIndex)
                }

                if !isLive {
                    Button(L10n.jumpBackward, systemImage: jumpBackwardInterval.secondarySystemImage) {
                        proxy.jumpBackward(jumpBackwardInterval.rawValue)
                    }
                    .buttonStyle(.remoteControl)
                } else if let onChannelDown {
                    Button(
                        GeneralCommandType.channelDown.displayTitle,
                        systemImage: GeneralCommandType.channelDown.systemImage,
                        action: onChannelDown
                    )
                    .buttonStyle(.remoteControl)
                }

                Button(
                    proxy.isPaused ? L10n.play : L10n.pause,
                    systemImage: proxy.isPaused ? "play.fill" : "pause.fill"
                ) {
                    if proxy.isPaused {
                        proxy.play()
                    } else {
                        proxy.pause()
                    }
                }
                .buttonStyle(.remoteControl(size: .large))

                if !isLive {
                    Button(L10n.jumpForward, systemImage: jumpForwardInterval.systemImage) {
                        proxy.jumpForward(jumpForwardInterval.rawValue)
                    }
                    .buttonStyle(.remoteControl)
                } else if let onChannelUp {
                    Button(
                        GeneralCommandType.channelUp.displayTitle,
                        systemImage: GeneralCommandType.channelUp.systemImage,
                        action: onChannelUp
                    )
                    .buttonStyle(.remoteControl)
                }

                if hasQueue {
                    Button(L10n.playNextItem, systemImage: "forward.end.fill") {
                        proxy.nextItem()
                    }
                    .buttonStyle(.remoteControl(size: .small))
                    .disabled(proxy.queueIndex == proxy.queueCount - 1)
                }
            }
        }
    }
}
