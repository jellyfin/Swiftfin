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

// TODO: remove timer and have viewmodel debounce
//       - or use `onReceive` for changes and trigger timer in views?

struct ActiveDevicesView: View {

    @StoredValue(.User.activeDevicesDisplayType)
    private var storedDisplayType: LibraryDisplayType

    @EnvironmentObject
    private var router: SettingsCoordinator.Router

    @State
    private var displayType: LibraryDisplayType
    @State
    private var layout: CollectionVGridLayout

    @StateObject
    private var viewModel = ActiveSessionsViewModel()

    private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    // MARK: - Init

    init() {

        let initialDisplayType = _storedDisplayType.wrappedValue
        self._displayType = State(initialValue: initialDisplayType)

        if UIDevice.isPhone {
            layout = Self.phoneLayout(viewType: initialDisplayType)
        } else {
            layout = Self.padLayout(viewType: initialDisplayType)
        }
    }

    // MARK: - Tablet Layout

    private static func padLayout(viewType: LibraryDisplayType) -> CollectionVGridLayout {
        switch viewType {
        case .grid:
            .columns(2)
        case .list:
            .columns(1, insets: .zero, itemSpacing: 4, lineSpacing: 4)
        }
    }

    // MARK: - Phone Layout

    private static func phoneLayout(viewType: LibraryDisplayType) -> CollectionVGridLayout {
        switch viewType {
        case .grid:
            .columns(1)
        case .list:
            .columns(1, insets: .zero, itemSpacing: 4, lineSpacing: 4)
        }
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        if viewModel.sessions.isEmpty {
            L10n.noResults.text
        } else {
            CollectionVGrid(
                viewModel.sessions,
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
    }

    @ViewBuilder
    private func gridItem(session: SessionInfo) -> some View {
        ActiveSessionButton(session: session) {
            router.route(
                to: \.activeDeviceDetails,
                ActiveSessionsViewModel(deviceID: session.deviceID)
            )
        }
    }

    @ViewBuilder
    private func listItem(session: SessionInfo) -> some View {
        ActiveSessionRow(session: session) {
            router.route(
                to: \.activeDeviceDetails,
                ActiveSessionsViewModel(deviceID: session.deviceID)
            )
        }
    }

    @ViewBuilder
    private func errorView(with error: some Error) -> some View {
        ErrorView(error: error)
            .onRetry {
                viewModel.send(.refreshSessions)
            }
    }

    // MARK: - Body

    @ViewBuilder
    var body: some View {
        ZStack {
            switch viewModel.state {
            case .content:
                contentView
            case let .error(error):
                errorView(with: error)
            case .initial:
                DelayedProgressView()
            }
        }
        .navigationTitle(L10n.activeDevices)
        .onReceive(timer) { _ in
            viewModel.send(.getSessions)
        }
        .onFirstAppear {
            viewModel.send(.refreshSessions)
        }
        .refreshable {
            viewModel.send(.refreshSessions)
        }
        .topBarTrailing {

            if viewModel.backgroundStates.contains(.gettingSessions) {
                ProgressView()
            }

            // TODO: menu along with filter
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
            }
        }
    }
}
