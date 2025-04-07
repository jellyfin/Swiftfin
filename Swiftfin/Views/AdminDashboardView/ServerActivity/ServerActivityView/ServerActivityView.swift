//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import CollectionVGrid
import JellyfinAPI
import SwiftUI

struct ServerActivityView: View {

    @EnvironmentObject
    private var router: AdminDashboardCoordinator.Router

    @StateObject
    private var viewModel = ServerActivityViewModel()
    @StateObject
    private var userViewModel = ServerUsersViewModel()

    // MARK: - Body

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .content:
                contentView
            case let .error(error):
                ErrorView(error: error)
                    .onRetry {
                        viewModel.send(.refresh)
                    }
            case .initial, .refreshing:
                DelayedProgressView()
            }
        }
        .animation(.linear(duration: 0.2), value: viewModel.state)
        .navigationTitle(L10n.activity)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarMenuButton(
            isLoading: viewModel.backgroundStates.contains(.gettingNextPage)
        ) {
            DatePicker(
                L10n.startDate,
                selection: Binding(
                    get: { viewModel.minDate ?? Date() },
                    set: { viewModel.minDate = $0 }
                ),
                displayedComponents: .date
            )

            Toggle(L10n.users, isOn: $viewModel.hasUserId)
        }
        .onFirstAppear {
            viewModel.send(.refresh)
            userViewModel.send(.getUsers())
        }
    }

    // MARK: - Device List View

    @ViewBuilder
    private var contentView: some View {
        if viewModel.elements.isEmpty {
            Text(L10n.none)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .listRowSeparator(.hidden)
                .listRowInsets(.zero)
        } else {
            CollectionVGrid(
                uniqueElements: viewModel.elements,
                id: \.unwrappedIDHashOrZero,
                layout: .columns(1)
            ) { entry in
                LogEntry(entry, users: userViewModel.users) {
                    router.route(to: \.activeSessions)
                }
            }
            .onReachedBottomEdge(offset: .offset(300)) {
                viewModel.send(.getNextPage)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
