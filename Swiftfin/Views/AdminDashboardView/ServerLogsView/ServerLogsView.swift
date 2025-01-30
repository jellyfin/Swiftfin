//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

// TODO: could filter based on known log names from server
//       - ffmpeg
//       - record-transcode
// TODO: download to device?
// TODO: super cool log parser?
//       - separate package

struct ServerLogsView: View {

    @StateObject
    private var viewModel = ServerLogsViewModel()

    @ViewBuilder
    private var contentView: some View {
        List {
            ListTitleSection(
                L10n.serverLogs,
                description: L10n.logsDescription
            ) {
                UIApplication.shared.open(URL(string: "https://jellyfin.org/docs/general/administration/troubleshooting")!)
            }
            ForEach(viewModel.logs, id: \.self) { log in
                Button {
                    let request = Paths.getLogFile(name: log.name!)
                    let url = viewModel.userSession.client.fullURL(with: request, queryAPIKey: true)!

                    UIApplication.shared.open(url)
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(log.name ?? .emptyDash)

                            if let modifiedDate = log.dateModified {
                                Text(modifiedDate, format: .dateTime)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Image(systemName: "arrow.up.forward")
                            .font(.body.weight(.regular))
                            .foregroundColor(.secondary)
                    }
                }
                .foregroundStyle(.primary, .secondary)
            }
        }
    }

    @ViewBuilder
    private func errorView(with error: some Error) -> some View {
        ErrorView(error: error)
            .onRetry {
                viewModel.send(.getLogs)
            }
    }

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
        .animation(.linear(duration: 0.2), value: viewModel.state)
        .navigationBarTitle(L10n.serverLogs)
        .onFirstAppear {
            viewModel.send(.getLogs)
        }
    }
}
