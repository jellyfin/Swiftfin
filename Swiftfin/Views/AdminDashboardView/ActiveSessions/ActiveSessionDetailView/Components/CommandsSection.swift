//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ActiveSessionDetailView {

    struct CommandsSection: View {

        @StateObject
        private var viewModel: SessionManagerViewModel

        private let session: SessionInfoDto

        @State
        private var message: String = ""
        @State
        private var isMessageAlertPresented = false

        init(session: SessionInfoDto) {
            self.session = session
            self._viewModel = StateObject(wrappedValue: .init(session))
        }

        // MARK: - Body

        var body: some View {
            if let supportedCommands = session.supportedCommands,
               session.isSupportsMediaControl == true ||
               supportedCommands.contains(.displayMessage)
            {
                Section(L10n.commands) {
                    if session.isSupportsMediaControl == true && session.nowPlayingItem != nil {
                        Button {
                            viewModel.send(.playState(.playPause))
                        } label: {
                            HStack {
                                Text(session.playState?.isPaused == true ? L10n.play : L10n.pause)
                                    .foregroundStyle(Color.primary)
                                Spacer()
                                Image(systemName: session.playState?.isPaused == true ? "play.fill" : "pause.fill")
                                    .foregroundStyle(Color.secondary)
                            }
                        }

                        Button {
                            viewModel.send(.playState(.stop))
                        } label: {
                            HStack {
                                Text(L10n.stop)
                                    .foregroundStyle(Color.primary)
                                Spacer()
                                Image(systemName: "stop.fill")
                                    .foregroundStyle(Color.secondary)
                            }
                        }
                    }

                    if supportedCommands.contains(.displayMessage) {
                        ChevronButton(L10n.message) {
                            isMessageAlertPresented = true
                        }
                        .alert(L10n.message, isPresented: $isMessageAlertPresented) {
                            TextField(L10n.message, text: $message)
                            Button(L10n.cancel, role: .cancel) {
                                message = ""
                            }
                            Button(L10n.send) {
                                viewModel.send(.message(message))
                                message = ""
                            }
                            .disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        } message: {
                            Text(L10n.sendMessageToRecipient(session.userName ?? session.deviceName ?? L10n.unknown))
                        }
                    }
                }
            }
        }
    }
}
