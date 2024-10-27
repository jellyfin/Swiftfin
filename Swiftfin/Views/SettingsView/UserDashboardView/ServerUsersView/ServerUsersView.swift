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

struct ServerUsersView: View {

    @EnvironmentObject
    private var router: SettingsCoordinator.Router

    @StateObject
    private var viewModel = ServerUsersViewModel()

    @State
    private var isPresentingDeleteUser: Bool = false

    @State
    private var includeHidden: Bool = true
    @State
    private var includeDisabled: Bool = true

    // MARK: - Body

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
        .navigationTitle(L10n.users)
        .onAppear {
            viewModel.send(.getUsers(includeHidden: includeHidden, includeDisabled: includeDisabled))
        }
        .refreshable {
            viewModel.send(.getUsers(includeHidden: includeHidden, includeDisabled: includeDisabled))
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

            Menu {
                Toggle(L10n.hidden, isOn: $includeHidden)
                    .onChange(of: includeHidden) { newValue in
                        viewModel.send(.getUsers(
                            includeHidden: newValue,
                            includeDisabled: includeDisabled
                        ))
                    }

                Toggle(L10n.disabled, isOn: $includeDisabled)
                    .onChange(of: includeDisabled) { newValue in
                        viewModel.send(.getUsers(
                            includeHidden: includeHidden,
                            includeDisabled: newValue
                        ))
                    }
            } label: {
                Label(L10n.filters, systemImage: "line.3.horizontal.decrease.circle")
            }

            if viewModel.users.isEmpty {
                HStack {
                    Spacer()
                    Text(L10n.none)
                    Spacer()
                }
                .listRowSeparator(.hidden)
                .listRowInsets(.zero)
            } else {
                ForEach(viewModel.users, id: \.self) { user in
                    ServerUsersRow(user: user) {
                        router.route(to: \.userDetails, user)
                    } onDelete: {
                        isPresentingDeleteUser = true
                    }
                    .listRowSeparator(.hidden)
                    .listRowInsets(.zero)
                }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Error View

    @ViewBuilder
    private func errorView(with error: some Error) -> some View {
        ErrorView(error: error)
            .onRetry {
                viewModel.send(.getUsers(includeHidden: includeHidden, includeDisabled: includeDisabled))
            }
    }
}
