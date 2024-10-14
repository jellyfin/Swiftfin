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
    private var router: AdminDashboardCoordinator.Router

    @StateObject
    private var viewModel = UserAdministrationViewModel()

    @State
    private var libraryDisplayType: LibraryDisplayType = .grid
    @State
    private var layout: CollectionVGridLayout

    // MARK: - Init

    init() {
        _layout = State(initialValue: Self.gridLayout)
    }

    // MARK: - Grid and List Layout

    private static var gridLayout: CollectionVGridLayout {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return .minWidth(150, insets: .edgeInsets, itemSpacing: 16, lineSpacing: 2)
        } else {
            return .columns(2, insets: .edgeInsets, itemSpacing: 8, lineSpacing: 8)
        }
    }

    private static var listLayout: CollectionVGridLayout {
        .columns(1, insets: .edgeInsets, itemSpacing: 8, lineSpacing: 8)
    }

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

            Button(action: {
                toggleView()
            }) {
                Image(systemName: libraryDisplayType == .list ? "square.grid.2x2" : "list.bullet")
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
                layout: $layout
            ) { id in
                if let user = viewModel.users[id]?.value {
                    if libraryDisplayType == .grid {
                        UserAdministrationButton(
                            observer: UserAdministrationObserver(user: user)
                        )
                        .frame(maxWidth: .infinity)
                    } else {
                        UserAdministrationRow(
                            observer: UserAdministrationObserver(user: user)
                        )
                        .frame(maxWidth: .infinity)
                    }
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

    // MARK: - Toggle Between Grid and List Views

    private func toggleView() {
        switch libraryDisplayType {
        case .list:
            libraryDisplayType = .grid
            layout = Self.gridLayout
        case .grid:
            libraryDisplayType = .list
            layout = Self.listLayout
        }
    }
}
