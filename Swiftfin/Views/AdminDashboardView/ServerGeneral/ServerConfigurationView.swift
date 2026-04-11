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

struct ServerConfigurationView: View {

    @Router
    private var router

    @StateObject
    private var viewModel = ServerConfigurationViewModel()

    @State
    private var tempConfiguration: ServerConfiguration?

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .initial:
                ProgressView()
            case .content:
                contentView
            case .error:
                viewModel.error.map {
                    ErrorView(error: $0)
                }
            }
        }
        .backport
        .toolbarTitleDisplayMode(.inline)
        .navigationTitle(L10n.general)
        .animation(.linear(duration: 0.2), value: viewModel.state)
        .topBarTrailing {
            Button(L10n.save) {
                if let tempConfiguration {
                    viewModel.update(tempConfiguration)
                }
            }
            .buttonStyle(.toolbarPill)
            .disabled(tempConfiguration == viewModel.configuration)
        }
        .onChange(of: viewModel.configuration) { newValue in
            tempConfiguration = newValue
        }
        .onFirstAppear {
            viewModel.refresh()
        }
    }

    @ViewBuilder
    private var contentView: some View {
        List {

            ListTitleSection(
                L10n.general,
                description: L10n.generalDescription,
            ) {
                UIApplication.shared.open(.jellyfinDocsSettings)
            }

            if tempConfiguration != nil {

                Section(L10n.name) {
                    TextField(
                        L10n.serverName,
                        text: Binding(
                            get: { tempConfiguration?.serverName ?? viewModel.configuration?.serverName ?? "" },
                            set: { tempConfiguration?.serverName = $0 }
                        )
                    )
                }

                Section(L10n.settings) {
                    CulturePicker(
                        L10n.metadataLanguage,
                        threeLetterISOLanguageName: Binding(
                            get: { tempConfiguration?.uICulture ?? "" },
                            set: { tempConfiguration?.uICulture = $0 }
                        )
                    )

                    Toggle(
                        L10n.quickConnect,
                        isOn: Binding(
                            get: { tempConfiguration?.isQuickConnectAvailable ?? false },
                            set: { tempConfiguration?.isQuickConnectAvailable = $0 }
                        )
                    )
                }

                Section {
                    ChevronButton(L10n.logs) {
                        router.route(to: .serverLogsSettings(viewModel: viewModel))
                    }
                    ChevronButton(L10n.paths) {
                        router.route(to: .serverPaths)
                    }
                }

                Section {
                    TextField(
                        L10n.libraryScanFanoutConcurrency,
                        value: Binding(
                            get: { tempConfiguration?.libraryScanFanoutConcurrency ?? 0 },
                            set: { tempConfiguration?.libraryScanFanoutConcurrency = $0 }
                        ),
                        format: .number
                    )
                    .keyboardType(.numberPad)
                } header: {
                    Text(L10n.libraryScanFanoutConcurrency)
                } footer: {
                    VStack(alignment: .leading) {
                        Text(L10n.libraryScanFanoutConcurrencyDescription)
                        Label(L10n.libraryScanFanoutConcurrencyWarning, systemImage: "exclamationmark.circle.fill")
                            .labelStyle(.sectionFooterWithImage(imageStyle: .orange))
                    }
                }

                Section {
                    TextField(
                        L10n.parallelImageEncodingLimit,
                        value: Binding(
                            get: { tempConfiguration?.parallelImageEncodingLimit ?? 0 },
                            set: { tempConfiguration?.parallelImageEncodingLimit = $0 }
                        ),
                        format: .number
                    )
                    .keyboardType(.numberPad)
                } header: {
                    Text(L10n.parallelImageEncodingLimit)
                } footer: {
                    Text(L10n.parallelImageEncodingLimitDescription)
                }
            }
        }
    }
}
