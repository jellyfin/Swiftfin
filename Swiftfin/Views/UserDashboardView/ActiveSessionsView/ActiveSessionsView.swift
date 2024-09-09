//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import CollectionVGrid
import Defaults
import JellyfinAPI
import SwiftUI

struct ActiveSessionsView: View {
    @EnvironmentObject
    private var router: SettingsCoordinator.Router
    @StateObject
    private var viewModel = ActiveSessionsViewModel()
    @State
    private var currentDate = Date.now

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var padLayout: CollectionVGridLayout {
        .columns(2)
    }

    private var phoneLayout: CollectionVGridLayout {
        .columns(1)
    }

    var body: some View {
        contentView
            .navigationTitle(L10n.activeDevices)
            .onReceive(timer) { _ in
                viewModel.send(.refresh)
            }
    }

    private var contentView: some View {
        CollectionVGrid(
            allSessions,
            layout: UIDevice.isPhone ? phoneLayout : padLayout
        ) { session in
            if allSessions.isEmpty {
                L10n.none.text
                    .foregroundColor(.secondary)
            } else {
                ActiveSessionButton(session: session)
                    .onSelect {
                        router.route(to: \.activeSessionDetails, session)
                    }
            }
        }
    }

    private var allSessions: [SessionInfo] {
        viewModel.sessions.sorted {
            // Group by sessions with nowPlayingItem first
            let isPlaying0 = $0.nowPlayingItem != nil
            let isPlaying1 = $1.nowPlayingItem != nil

            // Place streaming sessions before non-streaming
            if isPlaying0 && !isPlaying1 {
                return true
            } else if !isPlaying0 && isPlaying1 {
                return false
            }

            // Sort streaming vs non-streaming sessions by username
            if $0.userName != $1.userName {
                return ($0.userName ?? "") < ($1.userName ?? "")
            }

            // Both sessions are either playing or not, with the same userName
            if isPlaying0 && isPlaying1 {
                // If both are playing, sort by nowPlayingItem.name
                return ($0.nowPlayingItem?.name ?? "") < ($1.nowPlayingItem?.name ?? "")
            } else {
                // If neither is playing, sort by lastActivityDate
                return ($0.lastActivityDate ?? Date.distantPast) > ($1.lastActivityDate ?? Date.distantPast)
            }
        }
    }
}