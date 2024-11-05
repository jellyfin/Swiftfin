//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct MetadataEditorView: View {

    @EnvironmentObject
    private var router: MetadataEditorCoordinator.Router

    @ObservedObject
    var viewModel: RefreshMetadataViewModel

    // MARK: - Body

    var body: some View {
        List {
            ListTitleSection(
                L10n.metadata,
                description: L10n.metadataDescription
            ) {
                UIApplication.shared.open(URL.jellyfinDocsMetadata)
            }

            Section {
                refreshMenuView
            }

            Section(L10n.advanced) {
                ChevronButton(L10n.editWithItem(L10n.metadata))
                    .onSelect {
                        router.route(to: \.editMetadata)
                    }
                ChevronButton(L10n.editWithItem(L10n.people))
                    .onSelect {
                        router.route(to: \.editPeople)
                    }
                ChevronButton(L10n.editWithItem(L10n.studios))
                    .onSelect {
                        router.route(to: \.editStudios)
                    }
            }
        }
        .navigationTitle(L10n.metadata)
    }

    // MARK: - Refresh Menu

    private var refreshMenuView: some View {
        Menu {
            Button {
                viewModel.send(
                    .refreshMetadata(
                        metadataRefreshMode: .default,
                        imageRefreshMode: .default,
                        replaceMetadata: true,
                        replaceImages: false
                    )
                )
            } label: {
                Label(
                    L10n.refresh,
                    systemImage: "arrow.clockwise.circle"
                )
            }

            Button {
                viewModel.send(
                    .refreshMetadata(
                        metadataRefreshMode: .fullRefresh,
                        imageRefreshMode: .fullRefresh,
                        replaceMetadata: false,
                        replaceImages: false
                    )
                )
            } label: {
                Label(
                    L10n.findMissingMetadata,
                    systemImage: "magnifyingglass.circle"
                )
            }

            Button {
                viewModel.send(
                    .refreshMetadata(
                        metadataRefreshMode: .fullRefresh,
                        imageRefreshMode: .none,
                        replaceMetadata: true,
                        replaceImages: false
                    )
                )
            } label: {
                Label(
                    L10n.replaceMetadata,
                    systemImage: "document.circle"
                )
            }

            Button {
                viewModel.send(
                    .refreshMetadata(
                        metadataRefreshMode: .none,
                        imageRefreshMode: .fullRefresh,
                        replaceMetadata: false,
                        replaceImages: true
                    )
                )
            } label: {
                Label(
                    L10n.replaceImages,
                    systemImage: "photo.circle"
                )
            }

            Button {
                viewModel.send(
                    .refreshMetadata(
                        metadataRefreshMode: .fullRefresh,
                        imageRefreshMode: .fullRefresh,
                        replaceMetadata: true,
                        replaceImages: true
                    )
                )
            } label: {
                Label(
                    L10n.replaceAll,
                    systemImage: "staroflife.circle"
                )
            }
        } label: {
            HStack {
                Text(L10n.refreshMetadata)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "arrow.clockwise")
                    .foregroundStyle(.secondary)
            }
        }
        .foregroundStyle(.primary, .secondary)
    }
}
