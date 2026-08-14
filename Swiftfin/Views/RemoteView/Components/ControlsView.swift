//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Engine
import JellyfinAPI
import SwiftUI

extension RemoteView {

    struct ControlsView: View {

        @ObservedObject
        var proxy: CastMediaPlayerProxy
        @ObservedObject
        var target: SessionViewModel

        let viewModel: CastViewModel

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

        private var hasInputControls: Bool {
            supportedCommands.contains(.goToSearch) || supportedCommands.contains(.sendString)
        }

        private var hasVolumeControls: Bool {
            supportedCommands.contains(.toggleMute) || supportedCommands.contains(.setVolume) || proxy.queueItems.isNotEmpty
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
                    sendTextButton
                }
            }
        }

        @ViewBuilder
        private var sendTextButton: some View {
            StateAdapter(initialValue: false) { isPresentingTextEntry in
                StateAdapter(initialValue: "") { textEntry in
                    RemoteButton(systemImage: "keyboard", size: 44) {
                        isPresentingTextEntry.wrappedValue = true
                    }
                    .alert(L10n.sendText, isPresented: isPresentingTextEntry) {
                        TextField(L10n.sendText, text: textEntry)

                        Button(L10n.send) {
                            target.sendFullGeneralCommand(
                                GeneralCommand(
                                    arguments: ["String": textEntry.wrappedValue],
                                    name: .sendString
                                )
                            )

                            textEntry.wrappedValue = ""
                        }

                        Button(L10n.cancel, role: .cancel) {
                            textEntry.wrappedValue = ""
                        }
                    }
                }
            }
        }

        @ViewBuilder
        private var stopButton: some View {
            if proxy.displayedItem != nil {
                StateAdapter(initialValue: false) { isPresentingStopConfirmation in
                    Button(L10n.stop, systemImage: "stop.fill", role: .destructive) {
                        isPresentingStopConfirmation.wrappedValue = true
                    }
                    .labelStyle(.iconOnly)
                    .fontWeight(.semibold)
                    .tint(.red)
                    .foregroundStyle(.red)
                    .confirmationDialog(
                        L10n.stop,
                        isPresented: isPresentingStopConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button(L10n.stop, role: .destructive) {
                            perform(proxy.stop)
                        }

                        Button(L10n.cancel, role: .cancel) {}
                    } message: {
                        Text(L10n.stopPlaybackWarning)
                    }
                }
            }
        }

        var body: some View {
            VStack(spacing: 20) {
                if let displayedItem = proxy.displayedItem {
                    NowPlayingSection(
                        proxy: proxy,
                        item: displayedItem,
                        isLive: isLiveContent
                    )

                    PlaybackControls(
                        proxy: proxy,
                        isLive: isLiveContent,
                        supportedCommands: supportedCommands,
                        send: send,
                        perform: perform
                    )
                } else {
                    if hasDirectionalControls {
                        Touchpad(send: send)
                    } else {
                        ContentUnavailableView(L10n.nothingPlaying, systemImage: "play.slash")
                            .frame(maxHeight: .infinity)
                    }

                    navigationControlsSection

                    if hasInputControls {
                        inputSection
                    }
                }

                if hasVolumeControls {
                    VolumeSection(
                        proxy: proxy,
                        target: target,
                        supportedCommands: supportedCommands,
                        perform: perform,
                        onMenuPressed: setMenuPressed
                    )
                }
            }
            .edgePadding(.horizontal)
            .navigationBarMenuButton(
                isHidden: proxy.displayedItem == nil,
                onPressed: setMenuPressed
            ) {
                PlaybackMenu(
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
            .errorMessage($target.error)
        }
    }
}
