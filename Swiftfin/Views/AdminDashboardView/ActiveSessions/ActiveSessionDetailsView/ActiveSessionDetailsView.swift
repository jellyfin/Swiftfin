//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Engine
import Foundation
import JellyfinAPI
import SwiftUI
import SwiftUIIntrospect

struct ActiveSessionDetailsView: View {

    @Router
    private var router

    @ObservedObject
    var viewModel: SessionViewModel

    private var isPaused: Bool {
        viewModel.session.playState?.isPaused == true
    }

    @ViewBuilder
    private func playbackControls(session: SessionInfoDto) -> some View {
        ChevronButton(
            isPaused ? L10n.play : L10n.pause,
            systemName: isPaused ? "play.fill" : "pause.fill"
        ) {
            viewModel.sendPlaystateCommand(
                command: isPaused ? .unpause : .pause,
                seekPositionTicks: nil
            )
        }

        StateAdapter(initialValue: false) { isPresentingStopConfirmation in
            ChevronButton(L10n.stop, systemName: "stop.fill") {
                isPresentingStopConfirmation.wrappedValue = true
            }
            .confirmationDialog(
                L10n.stop,
                isPresented: isPresentingStopConfirmation,
                titleVisibility: .visible
            ) {
                Button(L10n.stop, role: .destructive) {
                    viewModel.sendPlaystateCommand(command: .stop, seekPositionTicks: nil)
                }

                Button(L10n.cancel, role: .cancel) {}
            } message: {
                Text(L10n.stopPlaybackWarning)
            }
        }
    }

    @ViewBuilder
    private func messageControl(session: SessionInfoDto) -> some View {
        StateAdapter(
            initialValue: (
                isPresented: false,
                header: L10n.messageFrom(viewModel.userSession?.user.username ?? L10n.server),
                text: ""
            )
        ) { alert in
            ChevronButton(L10n.message, systemName: "message.fill") {
                alert.wrappedValue = (
                    isPresented: true,
                    header: L10n.messageFrom(viewModel.userSession?.user.username ?? L10n.server),
                    text: ""
                )
            }
            .alert(L10n.message, isPresented: alert.isPresented) {
                TextField(L10n.title, text: alert.header)
                TextField(L10n.message, text: alert.text)

                Button(L10n.cancel, role: .cancel) {}

                Button(L10n.send) {
                    let command = MessageCommand(
                        header: alert.header.wrappedValue.isEmpty ? nil : alert.header.wrappedValue,
                        text: alert.text.wrappedValue
                    )
                    viewModel.sendMessage(command)
                }
                .disabled(alert.text.wrappedValue.isEmpty)
            }
        }
    }

    @ViewBuilder
    private func commandsSection(session: SessionInfoDto) -> some View {
        let hasPlaybackControls = session.isSupportsMediaControl == true && session.nowPlayingItem != nil
        let hasMessageControl = session.supportedCommands?.contains(.displayMessage) == true

        if hasPlaybackControls || hasMessageControl {
            Section {
                if hasPlaybackControls {
                    playbackControls(session: session)
                }

                if hasMessageControl {
                    messageControl(session: session)
                }
            }
        }
    }

    @ViewBuilder
    private func idleContent(session: SessionInfoDto) -> some View {
        List {
            if let userID = session.userID {
                let user = UserDto(id: userID, name: session.userName)

                AdminDashboardView.UserSection(
                    user: user,
                    lastActivityDate: session.lastActivityDate
                ) {
                    router.route(to: .userDetails(user: user))
                }
            }

            commandsSection(session: session)

            AdminDashboardView.DeviceSection(
                client: session.client,
                device: session.deviceName,
                version: session.applicationVersion
            )
        }
    }

    @ViewBuilder
    private func sessionContent(
        session: SessionInfoDto,
        nowPlayingItem: BaseItemDto,
        playState: PlayerStateInfo
    ) -> some View {
        List {

            FormItemSection(item: nowPlayingItem)

            ActiveSessionsView.ProgressSection(
                item: nowPlayingItem,
                playState: playState,
                transcodingInfo: session.transcodingInfo,
                showTranscodeReason: false
            )
            .listRowBackground(Color.clear)
            .listRowInsets(.zero)
            .listRowCornerRadius(0)

            commandsSection(session: session)

            if let userID = session.userID {
                let user = UserDto(id: userID, name: session.userName)

                AdminDashboardView.UserSection(
                    user: user,
                    lastActivityDate: session.lastPlaybackCheckIn
                ) {
                    router.route(to: .userDetails(user: user))
                }
            }

            AdminDashboardView.DeviceSection(
                client: session.client,
                device: session.deviceName,
                version: session.applicationVersion
            )

            // TODO: allow showing item stream details?
            // TODO: don't show codec changes on direct play?
            Section(L10n.streams) {
                if let playMethodDisplayTitle = session.playMethodDisplayTitle {
                    LabeledContent(
                        L10n.method,
                        value: playMethodDisplayTitle
                    )
                }

                StreamSection(
                    nowPlayingItem: nowPlayingItem,
                    transcodingInfo: session.transcodingInfo
                )
            }

            if let transcodeReasons = session.transcodingInfo?.transcodeReasons, transcodeReasons.isNotEmpty {
                Section(L10n.transcodeReasons) {
                    TranscodeSection(transcodeReasons: transcodeReasons)
                }
            }
        }
    }

    var body: some View {
        ZStack {
            let session = viewModel.session

            if let nowPlayingItem = session.nowPlayingItem, let playState = session.playState {
                sessionContent(
                    session: session,
                    nowPlayingItem: nowPlayingItem,
                    playState: playState
                )
            } else {
                idleContent(session: session)
            }
        }
        .animation(.linear(duration: 0.2), value: viewModel.session)
        .navigationTitle(L10n.session)
        .errorMessage($viewModel.error)
    }
}
