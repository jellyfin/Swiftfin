//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
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

    @ViewBuilder
    private var activeWithinFilterButton: some View {
        Picker(selection: $viewModel.environment.activeWithinSeconds) {
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

            if let activeWithinSeconds = viewModel.environment.activeWithinSeconds {
                Text(Duration.seconds(activeWithinSeconds).formatted(.units(allowed: [.hours, .minutes])))
            } else {
                Text(L10n.all)
            }

            Image(systemName: viewModel.environment.activeWithinSeconds == nil ? "infinity" : "clock")
        }
        .pickerStyle(.menu)
    }

    @ViewBuilder
    private var showInactiveSessionsButton: some View {
        Picker(selection: $viewModel.environment.showSessionType) {
            ForEach(ActiveSessionFilter.allCases, id: \.self) { filter in
                Label(
                    filter.displayTitle,
                    systemImage: filter.systemImage
                )
                .tag(filter)
            }
        } label: {
            Text(L10n.sessions)
            Text(viewModel.environment.showSessionType.displayTitle)
            Image(systemName: viewModel.environment.showSessionType.systemImage)
        }
        .pickerStyle(.menu)
    }

    @ViewBuilder
    private var contentView: some View {
        if viewModel.sessions.isEmpty {
            ContentUnavailableView(L10n.noActivity.localizedCapitalized, systemImage: "waveform.path.ecg")
        } else {
            CollectionVGrid(
                uniqueElements: viewModel.sessions.keys,
                id: \.self,
                layout: .columns(1, insets: .zero, itemSpacing: 0, lineSpacing: 0)
            ) { id in
                ActiveSessionRow(viewModel: viewModel.sessions[id]!) {
                    router.route(
                        to: .activeSessionDetails(viewModel: viewModel.sessions[id]!)
                    )
                }
            }
        }
    }

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .content:
                contentView
            case .error:
                viewModel.error.map {
                    ErrorView(error: $0)
                }
            case .initial:
                ProgressView()
            }
        }
        .backport
        .toolbarTitleDisplayMode(.inline)
        .navigationTitle(L10n.sessions)
        .animation(.linear(duration: 0.2), value: viewModel.state)
        .refreshable {
            viewModel.refresh()
        }
        .onFirstAppear {
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
                viewModel.environment.isPaused = isPressed
            })
        }
    }
}
