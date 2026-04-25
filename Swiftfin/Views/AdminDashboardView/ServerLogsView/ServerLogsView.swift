//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

struct ServerLogsView: View {

    @Router
    private var router

    @Default(.accentColor)
    private var accentColor

    @StateObject
    private var viewModel = ServerLogsViewModel()

    @ViewBuilder
    private var contentView: some View {
        List {
            ListTitleSection(
                L10n.serverLogs.localizedCapitalized,
                description: L10n.logsDescription
            ) {
                UIApplication.shared.open(.jellyfinDocsTroubleshooting)
            }

            if viewModel.logs.isNotEmpty {

                ForEach(viewModel.logs, id: \.self) { log in

                    ChevronButton {
                        router.route(to: .serverLogContents(log: log))
                    } label: {
                        LabeledContent {
                            EmptyView()
                        } label: {
                            VStack(alignment: .leading) {
                                Text(log.name ?? .emptyDash)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)

                                if let modifiedDate = log.dateModified {
                                    Text(modifiedDate, format: .dateTime)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            } else {
                Text(L10n.none)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .listRowSeparator(.hidden)
                    .listRowInsets(.zero)
            }
        }
    }

    private var filterMenu: some View {
        Menu(L10n.filters, systemImage: "line.3.horizontal.decrease.circle") {
            Picker(selection: $viewModel.filter) {
                Label(L10n.all, systemImage: "line.3.horizontal")
                    .tag(nil as ServerLogType?)

                ForEach(ServerLogType.allCases, id: \.self) { type in
                    Label(type.displayTitle, systemImage: type.systemImage)
                        .tag(type as ServerLogType?)
                }
            } label: {
                Text(L10n.logs)
                Text(viewModel.filter?.displayTitle ?? L10n.all)
                Image(systemName: viewModel.filter?.systemImage ?? "line.3.horizontal")
            }
            .pickerStyle(.menu)
        }
        .menuStyle(.button)
        .foregroundStyle(accentColor)
    }

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .error:
                viewModel.error.map {
                    ErrorView(error: $0)
                }
            case .content:
                contentView
            case .initial:
                ProgressView()
            }
        }
        .backport
        .toolbarTitleDisplayMode(.inline)
        .navigationTitle(L10n.serverLogs.localizedCapitalized)
        .animation(.linear(duration: 0.2), value: viewModel.state)
        .refreshable {
            viewModel.refresh()
        }
        .onFirstAppear {
            viewModel.refresh()
        }
        .topBarTrailing {
            filterMenu
        }
    }
}
