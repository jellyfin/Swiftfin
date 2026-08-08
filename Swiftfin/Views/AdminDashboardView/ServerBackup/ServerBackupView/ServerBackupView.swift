//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct ServerBackupView: View {

    @Router
    private var router

    @StateObject
    private var viewModel = ServerBackupViewModel()

    private var contentView: some View {
        List {
            ListTitleSection(
                L10n.backups,
                description: L10n.backupsDescription
            ) {
                UIApplication.shared.open(.jellyfinDocsBackup)
            }

            if viewModel.backups.isNotEmpty {
                ForEach(viewModel.backups, id: \.path) { backup in
                    ServerBackupRow(backup: backup) {
                        router.route(to: .backupDetails(viewModel: viewModel, backup: backup))
                    }
                    .foregroundStyle(.primary, .secondary)
                }
            } else {
                Button(L10n.add) {
                    router.route(to: .createBackup(viewModel: viewModel))
                }
            }
        }
    }

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
        .animation(.linear(duration: 0.1), value: viewModel.backups)
        .navigationTitle(L10n.backups)
        .refreshable {
            viewModel.refresh()
        }
        .onFirstAppear {
            viewModel.refresh()
        }
        .topBarTrailing {

            if viewModel.background.is(.creating) {
                ProgressView()
            }

            if viewModel.backups.isNotEmpty {
                Button(L10n.add) {
                    router.route(to: .createBackup(viewModel: viewModel))
                }
                .backport
                .buttonStyle(.glassProminent)
                .controlSize(.small)
            }
        }
        .onReceive(viewModel.events) { event in
            switch event {
            case .created:
                UIDevice.feedback(.success)
            case .restored:
                break
            }
        }
        .errorMessage($viewModel.error)
    }
}
