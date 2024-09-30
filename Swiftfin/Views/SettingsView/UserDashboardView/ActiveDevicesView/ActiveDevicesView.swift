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
// TODO: filter for streaming/inactive

struct ActiveDevicesView: View {

    @EnvironmentObject
    private var router: SettingsCoordinator.Router

    @State
    private var layout: CollectionVGridLayout = .columns(1, insets: .zero, itemSpacing: 4, lineSpacing: 4)

    @StateObject
    private var viewModel = ActiveSessionsViewModel()

    private let timer = Timer.publish(every: 5, on: .main, in: .common)
        .autoconnect()

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        if viewModel.sessions.isEmpty {
            L10n.noResults.text
        } else {
            CollectionVGrid(
                viewModel.sessions.keys,
                layout: $layout
            ) { id in
                ActiveSessionRow(box: viewModel.sessions[id]!) {
                    router.route(
                        to: \.activeDeviceDetails,
                        viewModel.sessions[id]!
                    )
                }
            }
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
        }
    }
}
