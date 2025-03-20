//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ItemView {

    struct RefreshMetadataButton: View {

        // MARK: - State Object

        @StateObject
        private var viewModel: RefreshMetadataViewModel

        // MARK: - Error State

        @State
        private var error: Error?

        // MARK: - Initializer

        init(item: BaseItemDto) {
            _viewModel = StateObject(wrappedValue: RefreshMetadataViewModel(item: item))
        }

        // MARK: - Body

        var body: some View {
            Menu {
                Group {
                    Button(L10n.findMissing, systemImage: "magnifyingglass") {
                        viewModel.send(
                            .refreshMetadata(
                                metadataRefreshMode: .fullRefresh,
                                imageRefreshMode: .fullRefresh,
                                replaceMetadata: false,
                                replaceImages: false
                            )
                        )
                    }

                    Button(L10n.replaceMetadata, systemImage: "arrow.clockwise") {
                        viewModel.send(
                            .refreshMetadata(
                                metadataRefreshMode: .fullRefresh,
                                imageRefreshMode: .none,
                                replaceMetadata: true,
                                replaceImages: false
                            )
                        )
                    }

                    Button(L10n.replaceImages, systemImage: "photo") {
                        viewModel.send(
                            .refreshMetadata(
                                metadataRefreshMode: .none,
                                imageRefreshMode: .fullRefresh,
                                replaceMetadata: false,
                                replaceImages: true
                            )
                        )
                    }

                    Button(L10n.replaceAll, systemImage: "staroflife") {
                        viewModel.send(
                            .refreshMetadata(
                                metadataRefreshMode: .fullRefresh,
                                imageRefreshMode: .fullRefresh,
                                replaceMetadata: true,
                                replaceImages: true
                            )
                        )
                    }
                }
            } label: {
                HStack {
                    Text(L10n.refreshMetadata)
                        .foregroundStyle(.primary)

                    Spacer()

                    Image(systemName: "arrow.clockwise")
                        .foregroundStyle(.secondary)
                        .backport
                        .fontWeight(.semibold)
                }
            }
            .foregroundStyle(.primary, .secondary)
            .disabled(viewModel.state == .refreshing || error != nil)
            .onReceive(viewModel.events) { event in
                switch event {
                case let .error(eventError):
                    error = eventError
                }
            }
            .errorMessage($error)
        }
    }
}
