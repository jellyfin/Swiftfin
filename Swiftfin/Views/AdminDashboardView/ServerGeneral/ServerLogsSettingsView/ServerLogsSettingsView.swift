//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct ServerLogsSettingsView: View {

    @Router
    private var router

    @ObservedObject
    private var viewModel: ServerConfigurationViewModel

    @State
    private var tempConfiguration: ServerConfiguration?

    init(viewModel: ServerConfigurationViewModel) {
        self.viewModel = viewModel
        self.tempConfiguration = viewModel.configuration
    }

    var body: some View {

        List {
            Section(L10n.logs) {
                Toggle(
                    L10n.enableSlowResponseWarning,
                    isOn: Binding(
                        get: { tempConfiguration?.enableSlowResponseWarning ?? false },
                        set: { tempConfiguration?.enableSlowResponseWarning = $0 }
                    )
                )

                Toggle(
                    L10n.allowClientLogUpload,
                    isOn: Binding(
                        get: { tempConfiguration?.allowClientLogUpload ?? false },
                        set: { tempConfiguration?.allowClientLogUpload = $0 }
                    )
                )
            }

            Section(L10n.logFileRetentionDays) {
                TextField(
                    L10n.logFileRetentionDays,
                    value: Binding(
                        get: { tempConfiguration?.logFileRetentionDays ?? 0 },
                        set: { tempConfiguration?.logFileRetentionDays = $0 }
                    ),
                    format: .number
                )
                .keyboardType(.numberPad)
            }

            Section(L10n.activityLogRetentionDays) {
                TextField(
                    L10n.activityLogRetentionDays,
                    value: Binding(
                        get: { tempConfiguration?.activityLogRetentionDays ?? 0 },
                        set: { tempConfiguration?.activityLogRetentionDays = $0 }
                    ),
                    format: .number
                )
                .keyboardType(.numberPad)
            }
        }
        .backport
        .toolbarTitleDisplayMode(.inline)
        .navigationTitle(L10n.logs)
    }
}
