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

    // MARK: - Environment Objects

    @EnvironmentObject
    private var router: AdminDashboardCoordinator.Router

    // MARK: - State Objects

    @StateObject
    private var viewModel = ServerActivityViewModel()

    // MARK: - Dialog States

    @State
    private var isDatePickerShowing: Bool = false
    @State
    private var tempDate: Date?

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
            Section(L10n.filters) {
                startDateButton
                userFilterButton
            }
        }
        .onFirstAppear {
            viewModel.send(.refresh)
        }
        .sheet(isPresented: $isDatePickerShowing, onDismiss: { isDatePickerShowing = false }) {
            startDatePickerSheet
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
                    router.route(to: \.activityDetails, logViewModel)
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
        Menu(
            L10n.type,
            systemImage: viewModel.hasUserId == true ? "person.fill" :
                viewModel.hasUserId == false ? "gearshape.fill" : "line.3.horizontal"
        ) {
            Picker(L10n.type, selection: $viewModel.hasUserId) {
                Section {
                    Label(
                        L10n.all,
                        systemImage: "line.3.horizontal"
                    )
                    .tag(nil as Bool?)
                }

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
            }
        }
    }

    // MARK: - Start Date Button

    @ViewBuilder
    private var startDateButton: some View {
        Button(L10n.startDate, systemImage: "calendar") {
            if let minDate = viewModel.minDate {
                tempDate = minDate
            } else {
                tempDate = .now
            }
            isDatePickerShowing = true
        }
    }

    // MARK: - Start Date Picker Sheet

    @ViewBuilder
    private var startDatePickerSheet: some View {
        NavigationView {
            List {
                Section {
                    DatePicker(
                        L10n.date,
                        selection: $tempDate.coalesce(.now),
                        in: ...Date.now,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                }

                /// Reset button to remove the filter
                if viewModel.minDate != nil {
                    Section {
                        ListRowButton(L10n.reset, role: .destructive) {
                            viewModel.minDate = nil
                            isDatePickerShowing = false
                        }
                    } footer: {
                        Text(L10n.resetFilterFooter)
                    }
                }
            }
            .navigationTitle(L10n.startDate.localizedCapitalized)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarCloseButton {
                isDatePickerShowing = false
            }
            .topBarTrailing {
                let startOfDay = Calendar.current
                    .startOfDay(for: tempDate ?? .now)

                Button(L10n.save) {
                    viewModel.minDate = startOfDay
                    isDatePickerShowing = false
                }
                .buttonStyle(.toolbarPill)
                .disabled(viewModel.minDate != nil && startOfDay == viewModel.minDate)
            }
        }
    }
}
