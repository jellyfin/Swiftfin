//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

// TODO: download to device?
// TODO: super cool log parser?
//       - separate package

struct ServerLogsView: View {

    @State
    private var filter: ServerLogType?

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
                    ChevronButton(external: true) {
                        guard let url = log.url else { return }
                        UIApplication.shared.open(url)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(log.name ?? L10n.unknown)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)

                            Text(log.dateModified, format: .dateTime)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } else {
                Text(L10n.none)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
    }

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .content:
                contentView
            case .initial:
                ProgressView()
            case .error:
                viewModel.error.map {
                    ErrorView(error: $0)
                }
            }
        }
        .backport
        .toolbarTitleDisplayMode(.inline)
        .navigationTitle(L10n.serverLogs.localizedCapitalized)
        .animation(.linear(duration: 0.2), value: viewModel.state)
        .refreshable {
            viewModel.refresh(filter: filter)
        }
        .onFirstAppear {
            viewModel.refresh(filter: filter)
        }
        .backport
        .onChange(of: filter) {
            viewModel.refresh(filter: filter)
        }
        .topBarTrailing {
            Menu(L10n.filters, systemImage: "line.3.horizontal.decrease.circle") {
                Picker(selection: $filter) {
                    Label(L10n.all, systemImage: "line.3.horizontal")
                        .tag(nil as ServerLogType?)

                    ForEach(ServerLogType.allCases) { type in
                        Label(type.displayTitle, systemImage: type.systemImage)
                            .tag(type as ServerLogType?)
                    }
                } label: {
                    Text(L10n.logs)
                    Text(filter?.displayTitle ?? L10n.all)
                    Image(systemName: filter?.systemImage ?? "line.3.horizontal")
                }
                .pickerStyle(.menu)
            }
        }
    }
}
