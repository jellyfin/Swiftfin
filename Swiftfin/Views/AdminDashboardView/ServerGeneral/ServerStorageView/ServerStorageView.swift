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
    private var viewModel = ServerConfigurationViewModel()

    var body: some View {
        List {
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
        .animation(.linear(duration: 0.2), value: viewModel.state)
        .backport
        .toolbarTitleDisplayMode(.inline)
        .navigationTitle(L10n.storage)
        .onFirstAppear {
            viewModel.refresh()
        }
    }

    @ViewBuilder
    private var contentView: some View {

        if let systemStorage = viewModel.systemStorage {

            Section(L10n.folders) {

                if let cacheFolder = systemStorage.cacheFolder {
                    FolderStorageButton(L10n.cache, folder: cacheFolder) {}
                }

                if let imageCacheFolder = systemStorage.imageCacheFolder {
                    FolderStorageButton(L10n.imageCache, folder: imageCacheFolder) {}
                }

                if let logFolder = systemStorage.logFolder {
                    FolderStorageButton(L10n.logs, folder: logFolder) {}
                }

                if let internalMetadataFolder = systemStorage.internalMetadataFolder {
                    FolderStorageButton(L10n.metadata, folder: internalMetadataFolder) {}
                }

                if let programDataFolder = systemStorage.programDataFolder {
                    FolderStorageButton(L10n.programData, folder: programDataFolder) {}
                }

                if let transcodingTempFolder = systemStorage.transcodingTempFolder {
                    FolderStorageButton(L10n.transcoding, folder: transcodingTempFolder) {}
                }

                if let webFolder = systemStorage.webFolder {
                    FolderStorageButton(L10n.web, folder: webFolder) {}
                }
            }
            .foregroundStyle(Color.primary, Color.secondary)
        }
    }
}
