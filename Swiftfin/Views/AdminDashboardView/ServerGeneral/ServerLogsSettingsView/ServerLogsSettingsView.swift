//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Engine
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
    }

    var body: some View {
        List {
            ListTitleSection(
                L10n.logs,
                description: L10n.logsDescription
            ) {
                UIApplication.shared.open(.jellyfinDocsTroubleshooting)
            }

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

            Section {
                StateAdapter(initialValue: false) { isPresented in
                    ChevronButton {
                        isPresented.wrappedValue = true
                    } label: {
                        LabeledContent(L10n.logFileRetentionDays) {
                            Text(tempConfiguration?.logFileRetentionDays ?? 0, format: .number)
                        }
                    }
                    .alert(
                        L10n.logFileRetentionDays,
                        isPresented: isPresented
                    ) {
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
                }

                StateAdapter(initialValue: false) { isPresented in
                    ChevronButton {
                        isPresented.wrappedValue = true
                    } label: {
                        LabeledContent(L10n.activityLogRetentionDays) {
                            Text(tempConfiguration?.activityLogRetentionDays ?? 0, format: .number)
                        }
                    }
                    .alert(
                        L10n.activityLogRetentionDays,
                        isPresented: isPresented
                    ) {
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
            }
        }
        .backport
        .toolbarTitleDisplayMode(.inline)
        .navigationTitle(L10n.logs)
        .topBarTrailing {
            Button(L10n.save) {
                if let tempConfiguration {
                    viewModel.update(tempConfiguration)
                }
            }
            .buttonStyle(.toolbarPill)
            .disabled(tempConfiguration == viewModel.configuration)
        }
        .onReceive(viewModel.events) { event in
            switch event {
            case .updated:
                UIDevice.feedback(.success)
            }
        }
        .onChange(of: viewModel.configuration) { newValue in
            tempConfiguration = newValue
        }
        .onFirstAppear {
            tempConfiguration = viewModel.configuration
        }
    }
}
