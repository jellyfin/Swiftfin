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

struct UserAdministrationView: View {

    @EnvironmentObject
    private var router: SettingsCoordinator.Router

    @StateObject
    private var viewModel = UserAdministrationViewModel()

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
        .navigationTitle("Users") // L10n.users)
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
        if viewModel.users.isEmpty {
            Text(L10n.none)
        } else {
            CollectionVGrid(
                viewModel.users.keys,
                layout: .columns(1, insets: .edgeInsets, itemSpacing: 8, lineSpacing: 8)
            ) { id in
                if let user = viewModel.users[id]?.value {
                    UserAdministrationRow(
                        observer: UserAdministrationObserver(user: user)
                    )
                    .frame(maxWidth: .infinity)
                }
            }
        }
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
