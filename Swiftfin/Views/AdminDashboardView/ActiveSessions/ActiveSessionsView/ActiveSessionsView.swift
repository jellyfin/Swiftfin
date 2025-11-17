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

    @Default(.accentColor)
    private var accentColor

    // MARK: - Router

    @Router
    private var router

    // MARK: - Track Filter State

    @State
    private var isFiltersPresented = false

    @StateObject
    private var viewModel = ActiveSessionsViewModel()

    private let timer = Timer.publish(every: 5, on: .main, in: .common)
        .autoconnect()

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        if viewModel.sessions.isEmpty {
            Text(L10n.none)
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

    // MARK: - Body

    @ViewBuilder
    var body: some View {
        ZStack {
            switch viewModel.state {
            case .error:
                viewModel.error.map {
                    ErrorView(error: $0)
                }
            case .initial:
                contentView
            case .refreshing:
                ProgressView()
            }
        }
        .animation(.linear(duration: 0.2), value: viewModel.state)
        .navigationTitle(L10n.sessions)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            viewModel.refresh()
        }
        .topBarTrailing {
            if viewModel.background.is(.refreshing) {
                ProgressView()
            }

            Menu(L10n.filters, systemImage: "line.3.horizontal.decrease.circle") {
                activeWithinFilterButton
                showInactiveSessionsButton
            }
            .menuStyle(.button)
            .buttonStyle(.isPressed { isPressed in
                isFiltersPresented = isPressed
            })
            .foregroundStyle(accentColor)
        }
        .onFirstAppear {
            viewModel.refresh()
        }
        .onReceive(timer) { _ in
            guard !isFiltersPresented else { return }
            viewModel.background.refresh()
        }
    }

    // MARK: - Active Within Filter Button

    @ViewBuilder
    private var activeWithinFilterButton: some View {
        Picker(selection: $viewModel.activeWithinSeconds) {
            Label(
                L10n.all,
                systemImage: "infinity"
            )
            .tag(nil as Int?)

            Label(
                Duration.seconds(300).formatted(.hourMinuteAbbreviated),
                systemImage: "clock"
            )
            .tag(300 as Int?)

            Label(
                Duration.seconds(900).formatted(.hourMinuteAbbreviated),
                systemImage: "clock"
            )
            .tag(900 as Int?)

            Label(
                Duration.seconds(1800).formatted(.hourMinuteAbbreviated),
                systemImage: "clock"
            )
            .tag(1800 as Int?)

            Label(
                Duration.seconds(3600).formatted(.hourMinuteAbbreviated),
                systemImage: "clock"
            )
            .tag(3600 as Int?)
        } label: {
            Text(L10n.lastSeen)

            if let activeWithinSeconds = viewModel.activeWithinSeconds {
                Text(Duration.seconds(activeWithinSeconds).formatted(.units(allowed: [.hours, .minutes])))
            } else {
                Text(L10n.all)
            }

            Image(systemName: viewModel.activeWithinSeconds == nil ? "infinity" : "clock")
        }
        .pickerStyle(.menu)
    }

    // MARK: - Show Inactive Sessions Button

    @ViewBuilder
    private var showInactiveSessionsButton: some View {
        Picker(selection: $viewModel.showSessionType) {
            ForEach(ActiveSessionFilter.allCases, id: \.self) { filter in
                Label(
                    filter.displayTitle,
                    systemImage: filter.systemImage
                )
                .tag(filter)
            }
        } label: {
            Text(L10n.sessions)
            Text(viewModel.showSessionType.displayTitle)
            Image(systemName: viewModel.showSessionType.systemImage)
        }
        .pickerStyle(.menu)
    }
}
