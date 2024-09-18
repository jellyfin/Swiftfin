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

struct ActiveDevicesView: View {
    @EnvironmentObject
    private var router: SettingsCoordinator.Router

    @StateObject
    private var viewModel = ActiveSessionsViewModel()

    @State
    private var layout: CollectionVGridLayout = .minWidth(200)

    let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    private static func padLayout(
        posterType: PosterDisplayType,
        viewType: LibraryDisplayType,
        listColumnCount: Int
    ) -> CollectionVGridLayout {
        switch (posterType, viewType) {
        case (.landscape, .grid):
            .minWidth(200)
        case (.portrait, .grid):
            .minWidth(150)
        case (_, .list):
            .columns(listColumnCount, insets: .zero, itemSpacing: 0, lineSpacing: 0)
        }
    }

    private static func phoneLayout(
        posterType: PosterDisplayType,
        viewType: LibraryDisplayType
    ) -> CollectionVGridLayout {
        switch (posterType, viewType) {
        case (.landscape, .grid):
            .columns(2)
        case (.portrait, .grid):
            .columns(3)
        case (_, .list):
            .columns(1, insets: .zero, itemSpacing: 0, lineSpacing: 0)
        }
    }

    @ViewBuilder
    private var contentView: some View {
        CollectionVGrid(
            orderedSessions,
            layout: $layout
        ) { session in
            gridItem(session: session)
        }
    }

    @ViewBuilder
    private func gridItem(session: SessionInfo) -> some View {
        UserDashboardView.ActiveSessionButton(session: session) {
            router.route(
                to: \.activeDeviceDetails,
                ActiveSessionsViewModel(deviceID: session.deviceID)
            )
        }
    }

    // MARK: Body

    @ViewBuilder
    var body: some View {
        contentView
            .onReceive(timer) { _ in
                viewModel.send(.backgroundRefresh)
            }
            .navigationTitle(L10n.activeDevices)
            .onAppear {
                viewModel.send(.refresh)
            }
            .refreshable {
                viewModel.send(.refresh)
            }
    }

    // MARK: Ordered Sessions

    private var orderedSessions: [SessionInfo] {
        viewModel.sessions.sorted {
            let isPlaying0 = $0.nowPlayingItem != nil
            let isPlaying1 = $1.nowPlayingItem != nil

            if isPlaying0 && !isPlaying1 {
                return true
            } else if !isPlaying0 && isPlaying1 {
                return false
            }

            if $0.userName != $1.userName {
                return ($0.userName ?? "") < ($1.userName ?? "")
            }

            if isPlaying0 && isPlaying1 {
                return ($0.nowPlayingItem?.name ?? "") < ($1.nowPlayingItem?.name ?? "")
            } else {
                return ($0.lastActivityDate ?? Date.distantPast) > ($1.lastActivityDate ?? Date.distantPast)
            }
        }
    }
}
