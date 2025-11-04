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

// TODO: WebSocket
struct ServerActivityView: View {

    // MARK: - Router

    @Router
    private var router

    // MARK: - State Objects

    @StateObject
    private var viewModel = ServerActivityViewModel()

    // MARK: - Body

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .content:
                contentView
            case let .error(error):
                ErrorView(error: error)
            case .initial, .refreshing:
                ProgressView()
            }
        }
        .animation(.linear(duration: 0.2), value: viewModel.state)
        .navigationTitle(L10n.activity)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            viewModel.send(.refresh)
        }
        .topBarTrailing {
            if viewModel.backgroundStates.contains(.gettingNextPage) {
                ProgressView()
            }

            Menu(L10n.filters, systemImage: "line.3.horizontal.decrease.circle") {
                startDateButton
                userFilterButton
            }
        }
        .onFirstAppear {
            viewModel.send(.refresh)
        }
    }

    // MARK: - Content View

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
            ) { log in

                let user = viewModel.users.first(
                    property: \.id,
                    equalTo: log.userID
                )

                let logViewModel = ServerActivityDetailViewModel(
                    log: log,
                    user: user
                )

                LogEntry(viewModel: logViewModel) {
                    router.route(to: .activityDetails(viewModel: logViewModel))
                }
            }
            .onReachedBottomEdge(offset: .offset(300)) {
                viewModel.send(.getNextPage)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - User Filter Button

    @ViewBuilder
    private var userFilterButton: some View {
        Picker(selection: $viewModel.hasUserId) {
            Label(
                L10n.all,
                systemImage: "line.3.horizontal"
            )
            .tag(nil as Bool?)

            Label(
                L10n.users,
                systemImage: "person"
            )
            .tag(true as Bool?)

            Label(
                L10n.system,
                systemImage: "gearshape"
            )
            .tag(false as Bool?)
        } label: {
            Text(L10n.type)

            if let hasUserID = viewModel.hasUserId {
                Text(hasUserID ? L10n.users : L10n.system)
                Image(systemName: hasUserID ? "person" : "gearshape")

            } else {
                Text(L10n.all)
                Image(systemName: "line.3.horizontal")
            }
        }
        .pickerStyle(.menu)
    }

    // MARK: - Start Date Button

    @ViewBuilder
    private var startDateButton: some View {
        Button {
            router.route(to: .activityFilters(viewModel: viewModel))
        } label: {
            Text(L10n.startDate)

            if let startDate = viewModel.minDate {
                Text(startDate.formatted(date: .numeric, time: .omitted))
            } else {
                Text(verbatim: .emptyDash)
            }

            Image(systemName: "calendar")
        }
    }
}
