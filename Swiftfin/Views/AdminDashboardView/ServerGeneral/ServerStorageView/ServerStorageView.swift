//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct ServerPathsView: View {

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
        .navigationTitle(L10n.paths)
        .onReceive(viewModel.events) { event in
            switch event {
            case .updated:
                UIDevice.feedback(.success)
            }
        }
        .animation(.linear(duration: 0.2), value: viewModel.state)
        .onChange(of: viewModel.configuration) { newValue in
            tempConfiguration = newValue
        }
        .onFirstAppear {
            viewModel.refresh()
            tempConfiguration = viewModel.configuration
        }
        .refreshable {
            viewModel.refresh()
            tempConfiguration = viewModel.configuration
        }
    }

    private func saveConfiguration() {
        if let tempConfiguration {
            viewModel.update(tempConfiguration)
        }
    }

    @ViewBuilder
    private var contentView: some View {
        List {
            InsetGroupedListHeader(
                L10n.paths,
                description: L10n.serverPathsDescription
            ) {
                UIApplication.shared.open(.jellyfinDocsServerPaths)
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .padding(.vertical, 24)

            if let systemStorage = viewModel.systemStorage {
                Section(L10n.customize) {
                    if let cacheFolder = systemStorage.cacheFolder {
                        FolderStorageButton(
                            L10n.cache,
                            folder: cacheFolder,
                            path: Binding(
                                get: { tempConfiguration?.cachePath ?? "" },
                                set: { tempConfiguration?.cachePath = $0 }
                            ),
                            onSave: saveConfiguration
                        )
                    }

                    if let internalMetadataFolder = systemStorage.internalMetadataFolder {
                        FolderStorageButton(
                            L10n.metadata,
                            folder: internalMetadataFolder,
                            path: Binding(
                                get: { tempConfiguration?.metadataPath ?? "" },
                                set: { tempConfiguration?.metadataPath = $0 }
                            ),
                            onSave: saveConfiguration
                        )
                    }
                }

                Section(L10n.folders) {
                    if let imageCacheFolder = systemStorage.imageCacheFolder {
                        FolderStorageButton(L10n.imageCache, folder: imageCacheFolder)
                    }

                    if let logFolder = systemStorage.logFolder {
                        FolderStorageButton(L10n.logs, folder: logFolder)
                    }

                    if let programDataFolder = systemStorage.programDataFolder {
                        FolderStorageButton(L10n.programData, folder: programDataFolder)
                    }

                    if let transcodingTempFolder = systemStorage.transcodingTempFolder {
                        FolderStorageButton(L10n.transcoding, folder: transcodingTempFolder)
                    }

                    if let webFolder = systemStorage.webFolder {
                        FolderStorageButton(L10n.web, folder: webFolder)
                    }
                }
            }
        }
        .listStyle(.plain)
        .foregroundStyle(Color.primary, Color.secondary)
    }
}
