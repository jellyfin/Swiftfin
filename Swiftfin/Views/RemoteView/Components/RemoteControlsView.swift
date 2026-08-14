//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct RemoteControlsView: View {

    @ObservedObject
    var proxy: CastMediaPlayerProxy
    @ObservedObject
    var target: SessionViewModel
    @ObservedObject
    var viewModel: CastViewModel

    @State
    private var isPresentingStopConfirmation = false
    @State
    private var isPresentingTextEntry = false
    @State
    private var textEntry = ""

    private var isLiveContent: Bool {
        guard let displayedItem = proxy.displayedItem else { return false }
        return displayedItem.isLiveStream || displayedItem.channelID != nil
    }

    private var supportedCommands: [GeneralCommandType] {
        target.session.supportedCommands ?? target.session.capabilities?.supportedCommands ?? []
    }

    private var hasDirectionalControls: Bool {
        supportedCommands.contains(.moveUp) || supportedCommands.contains(.select)
    }

    private func send(_ command: GeneralCommandType) {
        guard supportedCommands.contains(command) else { return }
        target.sendGeneralCommand(command)
    }

    private func perform(_ action: () -> Void) {
        setMenuPressed(false)
        action()
        viewModel.background.refresh()
    }

    private func setMenuPressed(_ isPressed: Bool) {
        viewModel.isPaused = isPressed
        proxy.isSyncSuspended = isPressed
    }

    @ViewBuilder
    private var navigationControlsSection: some View {
        HStack(spacing: 24) {
            RemoteButton(systemImage: "chevron.backward") {
                perform { send(.back) }
            }
            .disabled(!supportedCommands.contains(.back))

            RemoteButton(
                systemImage: proxy.isPaused ? "play.fill" : "pause.fill",
                size: 76
            ) {
                perform {
                    if proxy.isPaused {
                        proxy.play()
                    } else {
                        proxy.pause()
                    }
                }
            }

            RemoteButton(systemImage: "house.fill") {
                perform { send(.goHome) }
            }
            .disabled(!supportedCommands.contains(.goHome))
        }
    }

    @ViewBuilder
    private var inputSection: some View {
        HStack(spacing: 24) {
            if supportedCommands.contains(.goToSearch) {
                RemoteButton(
                    systemImage: GeneralCommandType.goToSearch.systemImage,
                    size: 44
                ) {
                    perform { send(.goToSearch) }
                }
            }

            if supportedCommands.contains(.sendString) {
                RemoteButton(systemImage: "keyboard", size: 44) {
                    isPresentingTextEntry = true
                }
            }
        }
    }

    @ViewBuilder
    private var stopButton: some View {
        if proxy.displayedItem != nil {
            Button(L10n.stop, systemImage: "stop.fill", role: .destructive) {
                isPresentingStopConfirmation = true
            }
            .labelStyle(.iconOnly)
            .fontWeight(.semibold)
            .tint(.red)
            .foregroundStyle(.red)
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            if let displayedItem = proxy.displayedItem {
                RemoteNowPlayingSection(
                    proxy: proxy,
                    item: displayedItem,
                    isLive: isLiveContent
                )

                RemotePlaybackControls(
                    proxy: proxy,
                    isLive: isLiveContent,
                    supportedCommands: supportedCommands,
                    send: send,
                    perform: perform
                )
            } else {
                if hasDirectionalControls {
                    RemoteTouchpad(send: send)
                } else {
                    ContentUnavailableView(L10n.nothingPlaying, systemImage: "play.slash")
                        .frame(maxHeight: .infinity)
                }

                navigationControlsSection

                if supportedCommands.contains(.goToSearch) || supportedCommands.contains(.sendString) {
                    inputSection
                }
            }

            if supportedCommands.contains(.toggleMute) || supportedCommands.contains(.setVolume) || proxy.queueItems
                .isNotEmpty
            {
                RemoteVolumeSection(
                    proxy: proxy,
                    target: target,
                    supportedCommands: supportedCommands,
                    perform: perform,
                    onMenuPressed: setMenuPressed
                )
            }
        }
        .edgePadding([.horizontal, .bottom])
        .navigationBarMenuButton(
            isHidden: proxy.displayedItem == nil,
            onPressed: setMenuPressed
        ) {
            RemotePlaybackMenu(
                proxy: proxy,
                target: target,
                supportedCommands: supportedCommands,
                perform: perform
            )
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                stopButton
            }
        }
        .confirmationDialog(
            L10n.stop,
            isPresented: $isPresentingStopConfirmation,
            titleVisibility: .visible
        ) {
            Button(L10n.stop, role: .destructive) {
                perform(proxy.stop)
            }

            Button(L10n.cancel, role: .cancel) {}
        } message: {
            Text(L10n.stopPlaybackWarning)
        }
        .alert(L10n.sendText, isPresented: $isPresentingTextEntry) {
            TextField(L10n.sendText, text: $textEntry)

            Button(L10n.send) {
                target.sendFullGeneralCommand(
                    GeneralCommand(
                        arguments: ["String": textEntry],
                        name: .sendString
                    )
                )

                textEntry = ""
            }

            Button(L10n.cancel, role: .cancel) {
                textEntry = ""
            }
        }
        .errorMessage($target.error)
    }
}
