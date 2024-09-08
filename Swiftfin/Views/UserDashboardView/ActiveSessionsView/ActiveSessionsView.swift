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
    @EnvironmentObject
    private var router: SettingsCoordinator.Router
    @StateObject
    private var viewModel = ActiveSessionsViewModel()

    var body: some View {
        List {
            Section(L10n.streams) {
                if activeSessions.isEmpty {
                    L10n.none.text
                        .foregroundColor(.secondary)
                } else {
                    ForEach(activeSessions.sorted {
                        if $0.userName != $1.userName {
                            return $0.userName ?? "" < $1.userName ?? ""
                        } else {
                            return ($0.nowPlayingItem?.name ?? "") < ($1.nowPlayingItem?.name ?? "")
                        }
                    }, id: \.id) { session in
                        ActiveSessionRowView(session: session) {
                            router.route(to: \.activeSessionDetails, session)
                        }
                    }
                }
            }
            Section(L10n.online) {
                if inactiveSessions.isEmpty {
                    L10n.none.text
                        .foregroundColor(.secondary)
                } else {
                    ForEach(inactiveSessions.sorted {
                        if $0.userName != $1.userName {
                            return $0.userName ?? "" < $1.userName ?? ""
                        } else {
                            return $0.lastActivityDate ?? Date.distantPast < $1.lastActivityDate ?? Date.distantPast
                        }
                    }, id: \.id) { session in
                        ActiveSessionRowView(session: session) {
                            router.route(to: \.activeSessionDetails, session)
                        }
                    }
                }
            }
        }
        .refreshable {
            viewModel.send(.refreshSessions)
        }
        .navigationTitle(L10n.activeDevices)
        .onAppear {
            viewModel.send(.loadSessions)
        }
    }

    private var activeSessions: [SessionInfo] {
        viewModel.sessions.filter { session in
            session.playState?.mediaSourceID != nil
        }
    }

    private var inactiveSessions: [SessionInfo] {
        viewModel.sessions.filter { session in
            session.playState?.mediaSourceID == nil
        }
    }
}
