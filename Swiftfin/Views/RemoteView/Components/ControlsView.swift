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
        private var proxy: CastMediaPlayerProxy
        @ObservedObject
        private var target: SessionViewModel

        private let viewModel: CastViewModel

        init(proxy: CastMediaPlayerProxy, viewModel: CastViewModel) {
            self.proxy = proxy
            self.target = proxy.session
            self.viewModel = viewModel
        }

        private var supportedCommands: [GeneralCommandType] {
            target.supportedCommands
        }

        private var hasAudioControls: Bool {
            supportedCommands.contains(.toggleMute) || supportedCommands.contains(.setVolume)
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

        var body: some View {
            VStack(spacing: 20) {
                if let activeItem = proxy.activeItem {
                    NowPlayingSection(
                        proxy: proxy,
                        item: activeItem
                    )

                    PlaybackControls(
                        proxy: proxy,
                        onChannelUp: supportedCommands.contains(.channelUp) ? { send(.channelUp) } : nil,
                        onChannelDown: supportedCommands.contains(.channelDown) ? { send(.channelDown) } : nil
                    )
                } else {
                    if supportedCommands.contains(.moveUp) || supportedCommands.contains(.select) {
                        Touchpad(send: send)
                    } else {
                        ContentUnavailableView(L10n.nothingPlaying, systemImage: "play.slash")
                            .frame(maxHeight: .infinity)
                    }

                    HStack(spacing: 24) {
                        Button(L10n.back, systemImage: "chevron.backward") {
                            perform { send(.back) }
                        }
                        .buttonStyle(.remoteControl)
                        .disabled(!supportedCommands.contains(.back))

                        Button(L10n.play, systemImage: "play.fill") {
                            perform(proxy.play)
                        }
                        .buttonStyle(.remoteControl(size: .large))
                        .disabled(true)

                        Button(L10n.home, systemImage: "house.fill") {
                            perform { send(.goHome) }
                        }
                        .buttonStyle(.remoteControl)
                        .disabled(!supportedCommands.contains(.goHome))
                    }

                    if supportedCommands.contains(.goToSearch) || supportedCommands.contains(.sendString) {
                        HStack(spacing: 24) {
                            if supportedCommands.contains(.goToSearch) {
                                Button(L10n.search, systemImage: GeneralCommandType.goToSearch.systemImage) {
                                    perform { send(.goToSearch) }
                                }
                                .buttonStyle(.remoteControl(size: .small))
                            }

                            if supportedCommands.contains(.sendString) {
                                StateAdapter(initialValue: false) { isPresentingTextEntry in
                                    StateAdapter(initialValue: "") { textEntry in
                                        Button(L10n.sendText, systemImage: "keyboard") {
                                            isPresentingTextEntry.wrappedValue = true
                                        }
                                        .buttonStyle(.remoteControl(size: .small))
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
                        }
                    }
                }

                if hasAudioControls || proxy.queueItems.isNotEmpty {
                    HStack(spacing: 16) {
                        if hasAudioControls {
                            VolumeSection(
                                proxy: proxy,
                                isMuteSupported: supportedCommands.contains(.toggleMute),
                                isVolumeSupported: supportedCommands.contains(.setVolume)
                            )
                        }

                        if proxy.queueItems.isNotEmpty {
                            Menu {
                                ForEach(proxy.queueItems, id: \.id) { queueItem in
                                    Button {
                                        perform { proxy.playQueueItem(queueItem) }
                                    } label: {
                                        if queueItem.id == proxy.activeItem?.id {
                                            Label(queueItem.displayTitle, systemImage: "play.fill")
                                        } else {
                                            Text(queueItem.displayTitle)
                                        }

                                        if let subtitle = queueItem.subtitle {
                                            Text(subtitle)
                                        }
                                    }
                                }
                            } label: {
                                Image(systemName: "list.bullet")
                            }
                            .menuStyle(.button)
                            .buttonStyle(.remoteControl(size: .small, onPressed: setMenuPressed))
                        }
                    }
                }
            }
            .edgePadding(.horizontal)
            .navigationBarMenuButton(
                isLoading: target.background.is(.sending),
                isHidden: proxy.activeItem == nil,
                onPressed: setMenuPressed
            ) {
                PlaybackMenu(
                    proxy: proxy,
                    perform: perform
                )
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if proxy.activeItem != nil {
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
            }
            .errorMessage($target.error)
        }
    }
}
