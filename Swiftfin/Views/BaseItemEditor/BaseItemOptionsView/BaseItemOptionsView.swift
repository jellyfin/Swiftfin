//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct BaseItemOptionsView: View {

    @EnvironmentObject
    private var router: BaseItemEditorCoordinator.Router

    @ObservedObject
    var viewModel: RefreshMetadataViewModel

    var body: some View {
        List {
            ListTitleSection(
                "Item Details",
                description: "Manage your metadata to organize and enrich your Jellyfin library’s information."
            ) {
                UIApplication.shared.open(URL.jellyfinDocsMetadata)
            }

            Section {
                refreshMenuView
            }

            Section(L10n.advanced) {
                ChevronButton("Edit metadata")
                    .onSelect {
                        router.route(to: \.editItemMetadata)
                    }
            }
        }
        .navigationTitle("Item Details")
    }

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
                    "Refresh",
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
                    "Find missing metadata",
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
                    "Replace metadata",
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
                    "Replace images",
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
                    "Replace all",
                    systemImage: "staroflife.circle"
                )
            }

        } label: {
            HStack {
                Text("Refresh metadata")
                Spacer()
                // TODO: Is there a way to show progress on a metadata refresh
                Image(systemName: "arrow.clockwise")
            }
        }
        .foregroundStyle(.primary)
    }
}
