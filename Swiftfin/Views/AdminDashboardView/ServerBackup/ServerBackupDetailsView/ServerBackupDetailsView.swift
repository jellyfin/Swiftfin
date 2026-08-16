//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Engine
import FactoryKit
import JellyfinAPI
import SwiftUI

struct ServerBackupDetailsView: View {

    @Injected(\.userSessionManager)
    private var userSessionManager: UserSessionManager

    @ObservedObject
    var viewModel: ServerBackupViewModel

    @State
    private var isPresentingConfirm: Bool = false
    @State
    private var isPresentingRestoreComplete: Bool = false

    let backup: BackupManifestDto

    var body: some View {
        List {
            Section(L10n.details) {
                LabeledContent(L10n.file) {
                    Text(URL(fileURLWithPath: backup.path).lastPathComponent)
                }

                LabeledContent(L10n.dateCreated) {
                    Text(backup.dateCreated, format: .dateTime)
                }
                .monospacedDigit()

                LabeledContent(L10n.server) {
                    Text(backup.serverVersion)
                }
                .monospacedDigit()
            }

            Section(L10n.location) {
                Text(backup.path)
                    .foregroundStyle(.secondary)
            }

            Section(L10n.components) {
                LabeledContent(L10n.database, value: backup.options.isDatabase == true ? L10n.yes : L10n.no)
                LabeledContent(L10n.metadata, value: backup.options.isMetadata == true ? L10n.yes : L10n.no)
                LabeledContent(L10n.subtitles, value: backup.options.isSubtitles == true ? L10n.yes : L10n.no)
                LabeledContent(L10n.trickplay, value: backup.options.isTrickplay == true ? L10n.yes : L10n.no)
            }
        }
        .navigationTitle(L10n.backup)
        .toolbarTitleDisplayMode(.inline)
        .topBarTrailing {
            if viewModel.background.is(.restoring) {
                ProgressView()
            }

            Button(L10n.restore, role: .destructive) {
                isPresentingConfirm = true
            }
            .backport
            .buttonStyle(.glassProminent)
            .controlSize(.small)
            .disabled(viewModel.background.is(.restoring))
            .confirmationDialog(
                L10n.restoreBackup,
                isPresented: $isPresentingConfirm,
                titleVisibility: .visible
            ) {
                Button(L10n.restore, role: .destructive) {
                    viewModel.restore(backup: backup)
                }

                Button(L10n.cancel, role: .cancel) {}
            } message: {
                Text(L10n.restoreWarning)
            }
        }
        .onReceive(viewModel.events) { event in
            switch event {
            case .created:
                break
            case .restored:
                UIDevice.feedback(.success)
                isPresentingRestoreComplete = true
            }
        }
        .alert(
            L10n.restoring,
            isPresented: $isPresentingRestoreComplete
        ) {
            Button(L10n.ok) {
                Task { @MainActor in
                    await userSessionManager.signOut(reason: .explicit)
                }
            }
        } message: {
            Text(L10n.restoringMessage)
        }
        .errorMessage($viewModel.error)
    }
}
