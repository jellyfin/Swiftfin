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
    private var layout: CollectionVGridLayout

    @StoredValue
    private var storedDisplayType: LibraryDisplayType

    @State
    private var displayType: LibraryDisplayType

    let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    // MARK: Init

    init() {
        self._storedDisplayType = StoredValue(.User.libraryDisplayType(parentID: "Active Devices"))

        let initialDisplayType = _storedDisplayType.wrappedValue
        self._displayType = State(initialValue: initialDisplayType)

        if UIDevice.isPhone {
            layout = Self.phoneLayout(viewType: initialDisplayType)
        } else {
            layout = Self.padLayout(viewType: initialDisplayType)
        }
    }

    // MARK: Tablet Layout

    private static func padLayout(viewType: LibraryDisplayType) -> CollectionVGridLayout {
        switch viewType {
        case .grid:
            .minWidth(200)
        case .list:
            .columns(1, insets: .zero, itemSpacing: 0, lineSpacing: 0)
        }
    }

    // MARK: Phone Layout

    private static func phoneLayout(viewType: LibraryDisplayType) -> CollectionVGridLayout {
        switch viewType {
        case .grid:
            .columns(1)
        case .list:
            .columns(1, insets: .zero, itemSpacing: 0, lineSpacing: 0)
        }
    }

    // MARK: Content View

    @ViewBuilder
    private var contentView: some View {
        CollectionVGrid(
            orderedSessions,
            layout: $layout
        ) { session in
            switch displayType {
            case .grid:
                gridItem(session: session)
            case .list:
                listItem(session: session)
            }
        }
    }

    // MARK: Grid View

    @ViewBuilder
    private func gridItem(session: SessionInfo) -> some View {
        ActiveSessionButton(session: session) {
            router.route(
                to: \.activeDeviceDetails,
                ActiveSessionsViewModel(deviceID: session.deviceID)
            )
        }
    }

    // MARK: Grid View

    @ViewBuilder
    private func listItem(session: SessionInfo) -> some View {
        ActiveSessionRow(session: session) {
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        if displayType == .grid {
                            displayType = .list
                        } else {
                            displayType = .grid
                        }

                        storedDisplayType = displayType

                        if UIDevice.isPhone {
                            layout = Self.phoneLayout(viewType: displayType)
                        } else {
                            layout = Self.padLayout(viewType: displayType)
                        }
                    } label: {
                        Image(systemName: displayType == .grid ? "list.bullet" : "square.grid.2x2")
                            .animation(.easeInOut)
                    }
                }
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
