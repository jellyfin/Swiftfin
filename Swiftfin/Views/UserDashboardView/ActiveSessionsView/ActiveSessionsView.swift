//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct ActiveSessionsView: View {
    @StateObject
    private var viewModel = ActiveSessionsViewModel()

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Streams")) {
                    if viewModel.isLoading {
                        ProgressView("Loading...")
                    } else if let error = viewModel.error {
                        Text("Failed to load sessions: \(error.localizedDescription)")
                            .foregroundColor(.red)
                    } else if viewModel.sessions.isEmpty {
                        L10n.none.text
                            .foregroundColor(.secondary)
                    } else {
                        if activeSessions.isEmpty {
                            L10n.none.text
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(activeSessions, id: \.id) { session in
                                ActiveSessionRowView(session: session)
                            }
                        }
                    }
                }
                Section(header: Text("Online")) {
                    if inactiveSessions.isEmpty {
                        Text("None")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(inactiveSessions, id: \.id) { session in
                            ActiveSessionRowView(session: session)
                        }
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadSessions()
        }
        .refreshable {
            viewModel.loadSessions()
        }
        .navigationTitle("Connected Devices")
        .toolbar {
            Button("Refresh") {
                viewModel.loadSessions()
            }
        }
    }

    private var activeSessions: [SessionInfo] {
        viewModel.sessions.filter { session in
            session.playState?.isPaused == true || session.playState?.mediaSourceID != nil
        }
    }

    private var inactiveSessions: [SessionInfo] {
        viewModel.sessions.filter { session in
            session.playState?.isPaused != true && session.playState?.mediaSourceID == nil
        }
    }
}
