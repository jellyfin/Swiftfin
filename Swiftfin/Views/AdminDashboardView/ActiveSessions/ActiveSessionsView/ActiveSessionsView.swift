//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import CollectionVGrid
import Defaults
import JellyfinAPI
import SwiftUI

struct ActiveSessionsView: View {

    @Router
    private var router

    @StateObject
    private var viewModel = ActiveSessionsViewModel()

    private let timer = Timer.publish(every: 5, on: .main, in: .common)
        .autoconnect()

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        if viewModel.sessions.isEmpty {
            L10n.none.text
        } else {
            CollectionVGrid(
                uniqueElements: viewModel.sessions.keys,
                id: \.self,
                layout: .columns(1, insets: .zero, itemSpacing: 0, lineSpacing: 0)
            ) { id in
                ActiveSessionRow(box: viewModel.sessions[id]!) {
                    router.route(
                        to: .activeDeviceDetails(box: viewModel.sessions[id]!)
                    )
                }
            }
        }
    }

    @ViewBuilder
    private func errorView(with error: some Error) -> some View {
        ErrorView(error: error)
            .onRetry {
                viewModel.send(.refresh)
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
        .animation(.linear(duration: 0.2), value: viewModel.state)
        .navigationTitle(L10n.sessions)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarMenuButton(
            isLoading: viewModel.backgroundStates.contains(.backgroundRefreshing)
        ) {
            Section(L10n.filters) {
                activeWithinFilterButton
                showInactiveSessionsButton
            }
        }
        .onFirstAppear {
            viewModel.send(.refresh)
        }
        .onReceive(timer) { _ in
            viewModel.send(.backgroundRefresh)
        }
        .refreshable {
            viewModel.send(.refresh)
        }
    }

    // MARK: - Active Within Filter Button

    @ViewBuilder
    private var activeWithinFilterButton: some View {
        Menu(
            L10n.lastSeen,
            systemImage: viewModel.activeWithinSeconds == nil ? "infinity" : "clock"
        ) {
            Picker(L10n.lastSeen, selection: $viewModel.activeWithinSeconds) {
                Label(
                    L10n.all,
                    systemImage: "infinity"
                )
                .tag(nil as Int?)

                Label(
                    300.formatted(.hourMinute),
                    systemImage: "clock"
                )
                .tag(300 as Int?)

                Label(
                    900.formatted(.hourMinute),
                    systemImage: "clock"
                )
                .tag(900 as Int?)

                Label(
                    1800.formatted(.hourMinute),
                    systemImage: "clock"
                )
                .tag(1800 as Int?)

                Label(
                    3600.formatted(.hourMinute),
                    systemImage: "clock"
                )
                .tag(3600 as Int?)
            }
        }
    }

    // MARK: - Show Inactive Sessions Button

    @ViewBuilder
    private var showInactiveSessionsButton: some View {
        Menu(
            L10n.sessions,
            systemImage: viewModel.showSessionType.systemImage
        ) {
            Picker(L10n.sessions, selection: $viewModel.showSessionType) {
                ForEach(ActiveSessionFilter.allCases, id: \.self) { filter in
                    Label(
                        filter.displayTitle,
                        systemImage: filter.systemImage
                    )
                    .tag(filter)
                }
            }
        }
    }
}
