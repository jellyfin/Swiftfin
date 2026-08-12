//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ServerBackupView {

    struct ServerBackupRow: View {

        let backup: BackupManifestDto
        let action: () -> Void

        var body: some View {
            ChevronButton(action: action) {
                VStack(alignment: .leading, spacing: 4) {

                    Text(URL(fileURLWithPath: backup.path).lastPathComponent)
                        .foregroundStyle(.primary)
                        .fontWeight(.semibold)
                        .lineLimit(2)

                    LabeledContent(L10n.dateCreated) {
                        Text(backup.dateCreated, format: .dateTime)
                    }
                    .monospacedDigit()

                    LabeledContent(L10n.version) {
                        Text(backup.serverVersion)
                    }
                    .monospacedDigit()
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
            }
        }
    }
}
