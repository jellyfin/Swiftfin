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

struct UsersView: View {

    @EnvironmentObject
    private var router: SettingsCoordinator.Router

    @StateObject
    private var viewModel = UsersViewModel()

    // MARK: - Body

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .content:
                if viewModel.users.isEmpty {
                    Text(L10n.none)
                } else {
                    contentView
                }
            case let .error(error):
                errorView(with: error)
            case .initial:
                DelayedProgressView()
            }
        }
        .navigationTitle(L10n.users)
        .onFirstAppear {
            viewModel.send(.getUsers)
        }
        .refreshable {
            viewModel.send(.getUsers)
        }
        .topBarTrailing {
            if viewModel.backgroundStates.contains(.gettingUsers) {
                ProgressView()
            }
        }
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        List {
            InsetGroupedListHeader(
                L10n.users,
                description: L10n.allUsersDescription
            ) {
                UIApplication.shared.open(.jellyfinDocsUsers)
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .padding(.vertical, 24)

            ForEach(viewModel.users, id: \.self) { user in
                UsersRow(user: user) {
                    router.route(to: \.userDetails, UserAdminViewModel(user: user))
                } onDelete: {
                    // TODO: Do we even want to allow User Deletion?
                }
                .listRowSeparator(.hidden)
                .listRowInsets(.zero)
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Error View

    @ViewBuilder
    private func errorView(with error: some Error) -> some View {
        ErrorView(error: error)
            .onRetry {
                viewModel.send(.getUsers)
            }
    }
}
