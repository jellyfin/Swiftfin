//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct ItemMetadataRefreshView: View {

    @Router
    private var router

    @ObservedObject
    var viewModel: RefreshMetadataViewModel

    @State
    private var metadataRefreshMode: MetadataRefreshMode = .default
    @State
    private var imageRefreshMode: MetadataRefreshMode = .default

    @State
    private var replaceMetadata: Bool = false
    @State
    private var replaceImages: Bool = false
    @State
    private var regenerateTrickplay: Bool = false

    var body: some View {
        Form {
            Section {
                Picker(L10n.metadata, selection: $metadataRefreshMode) {
                    ForEach(MetadataRefreshMode.allCases, id: \.self) { mode in
                        Text(mode.displayTitle)
                            .tag(mode)
                    }
                }

                Picker(L10n.images, selection: $imageRefreshMode) {
                    ForEach(MetadataRefreshMode.allCases, id: \.self) { mode in
                        Text(mode.displayTitle)
                            .tag(mode)
                    }
                }
            } header: {
                Text(L10n.refreshType)
            } footer: {
                LearnMoreButton(L10n.none) {
                    // TODO: Confirm this is what these options mean and localize
                    LabeledContent(
                        L10n.none,
                        value: "Skip the refresh for this metadata type."
                    )
                    LabeledContent(
                        L10n.validationOnly,
                        value: "Only refresh this metadata type if there currently is no metadata."
                    )
                    LabeledContent(
                        L10n.default,
                        value: "Refresh this metadata type using only the default metadata provider."
                    )
                    LabeledContent(
                        L10n.fullRefresh,
                        value: "Refresh this metadata type using all available metadata providers."
                    )
                }
            }

            Section(L10n.replace) {
                Toggle(L10n.metadata, isOn: $replaceMetadata)
                Toggle(L10n.images, isOn: $replaceImages)
                Toggle(L10n.trickplays, isOn: $regenerateTrickplay)
            }
        }
        .navigationTitle(L10n.refreshMetadata.localizedCapitalized)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarCloseButton {
            router.dismiss()
        }
        .topBarTrailing {
            Button(L10n.run) {
                viewModel.refreshMetadata(
                    metadataRefreshMode: metadataRefreshMode,
                    imageRefreshMode: imageRefreshMode,
                    replaceMetadata: replaceMetadata,
                    replaceImages: replaceImages,
                    regenerateTrickplay: regenerateTrickplay
                )
            }
            .buttonStyle(.toolbarPill)
        }
        .onReceive(viewModel.events) { event in
            switch event {
            case .refreshing:
                router.dismiss()
            }
        }
        .errorMessage($viewModel.error)
    }
}
