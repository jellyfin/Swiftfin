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

struct RemotePlaybackControls: View {

    @Default(.VideoPlayer.jumpBackwardInterval)
    private var jumpBackwardInterval
    @Default(.VideoPlayer.jumpForwardInterval)
    private var jumpForwardInterval

    @ObservedObject
    var proxy: CastMediaPlayerProxy

    let isLive: Bool
    let supportedCommands: [GeneralCommandType]
    let send: (GeneralCommandType) -> Void
    let perform: (() -> Void) -> Void

    private var hasQueue: Bool {
        proxy.queueCount > 1
    }

    var body: some View {
        HStack(spacing: 32) {
            if hasQueue {
                let isDisabled = proxy.queueIndex == 0

                Button {
                    perform(proxy.previousItem)
                } label: {
                    Image(systemName: "backward.end.fill")
                        .font(.title2)
                        .frame(width: 44, height: 44)
                        .foregroundStyle(isDisabled ? .secondary : .primary)
                }
                .disabled(isDisabled)
            }

            if !isLive {
                Button {
                    perform { proxy.jumpBackward(jumpBackwardInterval.rawValue) }
                } label: {
                    Image(systemName: jumpBackwardInterval.secondarySystemImage)
                        .font(.title)
                        .frame(width: 44, height: 44)
                }
            } else if supportedCommands.contains(.channelDown) {
                Button {
                    perform { send(.channelDown) }
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.title)
                        .frame(width: 44, height: 44)
                }
            }

            Button {
                perform {
                    if proxy.isPaused {
                        proxy.play()
                    } else {
                        proxy.pause()
                    }
                }
            } label: {
                Image(systemName: proxy.isPaused ? "play.fill" : "pause.fill")
                    .font(.system(size: 48))
                    .contentTransition(.symbolEffect(.replace))
                    .frame(width: 60, height: 60)
            }

            if !isLive {
                Button {
                    perform { proxy.jumpForward(jumpForwardInterval.rawValue) }
                } label: {
                    Image(systemName: jumpForwardInterval.systemImage)
                        .font(.title)
                        .frame(width: 44, height: 44)
                }
            } else if supportedCommands.contains(.channelUp) {
                Button {
                    perform { send(.channelUp) }
                } label: {
                    Image(systemName: "chevron.up")
                        .font(.title)
                        .frame(width: 44, height: 44)
                }
            }

            if hasQueue {
                let isDisabled = proxy.queueIndex == proxy.queueCount - 1

                Button {
                    perform(proxy.nextItem)
                } label: {
                    Image(systemName: "forward.end.fill")
                        .font(.title2)
                        .frame(width: 44, height: 44)
                        .foregroundStyle(isDisabled ? .secondary : .primary)
                }
                .disabled(isDisabled)
            }
        }
        .foregroundStyle(.primary)
    }
}
