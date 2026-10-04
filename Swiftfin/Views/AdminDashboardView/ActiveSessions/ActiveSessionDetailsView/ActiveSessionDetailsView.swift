//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import SwiftUI

struct ActiveSessionDetailsView: View {

    @ObservedObject
    var viewModel: SessionViewModel

    @Router
    private var router

    @State
    private var isPresentingStopConfirmation = false
    @State
    private var isPresentingMessage = false
    @State
    private var messageHeader = ""
    @State
    private var messageText = ""

    private var isPaused: Bool {
        viewModel.session.playState?.isPaused == true
    }

    private var canControl: Bool {
        guard let user = viewModel.userSession?.user else { return false }
        let session = viewModel.session

        return user.data.policy?.enableRemoteControlOfOtherUsers == true
            || session.userID == nil
            || session.userID == user.id
            || session.additionalUsers?.contains { $0.userID == user.id } == true
    }

    private var hasPlaybackControls: Bool {
        canControl && viewModel.session.isSupportsMediaControl == true && viewModel.session.nowPlayingItem != nil
    }

    private var hasMessageControl: Bool {
        viewModel.session.supportedCommands?.contains(.displayMessage) == true
    }

    @ViewBuilder
    private func transcodeComparison(_ title: String, source: String?, destination: String?) -> some View {
        if let source {
            LabeledContent(title) {
                if let destination, destination.lowercased() != source.lowercased() {
                    HStack(spacing: 4) {
                        Text(source.uppercased())
                        Image(systemName: "arrow.right")
                            .font(.footnote)
                        Text(destination.uppercased())
                    }
                } else {
                    Text(source.uppercased())
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
        let mediaStreams = nowPlayingItem.mediaStreams ?? []
        let audioStreams = mediaStreams.filter { $0.type == .audio }
        let videoStream = mediaStreams.first { $0.type == .video }
        let audioStream = audioStreams.first { $0.index == playState.audioStreamIndex } ?? audioStreams.first
        let subtitleStream = mediaStreams.first { $0.type == .subtitle && $0.index == playState.subtitleStreamIndex }

        List {

            FormItemSection(item: nowPlayingItem)

            ActiveSessionsView.ProgressSection(
                item: nowPlayingItem,
                playState: playState,
                transcodingInfo: session.transcodingInfo
            )
            .listRowBackground(Color.clear)
            .listRowInsets(.zero)
            .listRowCornerRadius(0)

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

            Section(L10n.source) {
                if let videoStream {
                    ChevronButton(videoStream.displayTitle ?? .emptyDash, systemName: "film") {
                        router.route(to: .mediaStreamInfo(mediaStream: videoStream))
                    }
                }

                if let audioStream {
                    ChevronButton(audioStream.displayTitle ?? .emptyDash, systemName: "speaker.wave.2") {
                        router.route(to: .mediaStreamInfo(mediaStream: audioStream))
                    }
                }

                if let subtitleStream {
                    ChevronButton(subtitleStream.displayTitle ?? .emptyDash, systemName: "captions.bubble") {
                        router.route(to: .mediaStreamInfo(mediaStream: subtitleStream))
                    }
                }
            }

            Section(L10n.playback) {
                if let playMethodDisplayTitle = session.playMethodDisplayTitle {
                    LabeledContent(
                        L10n.method,
                        value: playMethodDisplayTitle
                    )
                }

                if let transcodingInfo = session.transcodingInfo {
                    transcodeComparison(
                        L10n.video,
                        source: videoStream?.codec,
                        destination: transcodingInfo.videoCodec
                    )

                    transcodeComparison(
                        L10n.audio,
                        source: audioStream?.codec,
                        destination: transcodingInfo.audioCodec
                    )

                    transcodeComparison(
                        L10n.container,
                        source: nowPlayingItem.container,
                        destination: transcodingInfo.container
                    )
                }
            }

            if let transcodeReasons = session.transcodingInfo?.transcodeReasons, transcodeReasons.isNotEmpty {
                Section(L10n.transcodeReasons) {
                    ForEach(transcodeReasons, id: \.self) { reason in
                        Label(reason.displayTitle, systemImage: reason.systemImage)
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
        .symbolRenderingMode(.monochrome)
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
        .navigationBarMenuButton(isHidden: !hasPlaybackControls && !hasMessageControl) {

            if hasMessageControl {
                Button(L10n.message, systemImage: "message.fill") {
                    // swiftlint:disable:next nested_l10n
                    messageHeader = L10n.messageFrom(viewModel.userSession?.user.username ?? L10n.server)
                    messageText = ""
                    isPresentingMessage = true
                }
            }

            if hasPlaybackControls {
                Button(
                    isPaused ? L10n.play : L10n.pause,
                    systemImage: isPaused ? "play.fill" : "pause.fill"
                ) {
                    viewModel.sendPlaystateCommand(
                        command: isPaused ? .unpause : .pause,
                        seekPositionTicks: nil
                    )
                }

                Button(L10n.stop, systemImage: "stop.fill", role: .destructive) {
                    isPresentingStopConfirmation = true
                }
            }
        }
        .confirmationDialog(
            L10n.stop,
            isPresented: $isPresentingStopConfirmation,
            titleVisibility: .visible
        ) {
            Button(L10n.stop, role: .destructive) {
                viewModel.sendPlaystateCommand(command: .stop, seekPositionTicks: nil)
            }

            Button(L10n.cancel, role: .cancel) {}
        } message: {
            Text(L10n.stopPlaybackWarning)
        }
        .alert(L10n.message, isPresented: $isPresentingMessage) {
            TextField(L10n.title, text: $messageHeader)
            TextField(L10n.message, text: $messageText)

            Button(L10n.cancel, role: .cancel) {}

            Button(L10n.send) {
                viewModel.sendMessage(
                    .init(
                        header: messageHeader.nilIfBlank ?? messageHeader,
                        text: messageText
                    )
                )
            }
            .disabled(messageText.isEmpty)
        }
        .errorMessage($viewModel.error)
    }
}
