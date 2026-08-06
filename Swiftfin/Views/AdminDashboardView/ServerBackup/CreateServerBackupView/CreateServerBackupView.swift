//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct CreateServerBackupView: View {

    @Router
    private var router

    @ObservedObject
    var viewModel: ServerBackupViewModel

    @State
    private var backupOptions = BackupOptionsDto()

    private var isValid: Bool {
        [
            backupOptions.isDatabase,
            backupOptions.isMetadata,
            backupOptions.isSubtitles,
            backupOptions.isTrickplay,
        ]
            .contains(true)
    }

    var body: some View {
        Form {
            Section {
                Toggle(L10n.database, isOn: $backupOptions.isDatabase.coalesce(false))
                Toggle(L10n.metadata, isOn: $backupOptions.isMetadata.coalesce(false))
                Toggle(L10n.subtitles, isOn: $backupOptions.isSubtitles.coalesce(false))
                Toggle(L10n.trickplay, isOn: $backupOptions.isTrickplay.coalesce(false))
            } header: {
                Text(L10n.components)
            } footer: {
                if !isValid {
                    Label(L10n.componentMustBeSelected, systemImage: "exclamationmark.circle.fill")
                        .labelStyle(.sectionFooterWithImage(imageStyle: .orange))
                }
            }
        }
        .navigationTitle(L10n.createBackup.localizedCapitalized)
        .backport
        .toolbarTitleDisplayMode(.inline)
        .navigationBarCloseButton {
            router.dismiss()
        }
        .topBarTrailing {
            let saveAction: () -> Void = {
                UIDevice.impact(.light)
                viewModel.createBackup(options: backupOptions)
                router.dismiss()
            }

            Group {
                if #available(iOS 26, *) {
                    Button(L10n.save, role: .confirm, action: saveAction)
                } else {
                    Button(L10n.save, action: saveAction)
                        .backport
                        .buttonStyle(.glassProminent)
                        .controlSize(.small)
                }
            }
            .disabled(!isValid)
        }
    }
}
