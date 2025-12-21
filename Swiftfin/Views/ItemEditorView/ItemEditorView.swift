//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Factory
import JellyfinAPI
import SwiftUI

struct ItemEditorView: View {

    @Router
    private var router

    @ObservedObject
    var viewModel: ItemViewModel

    @StateObject
    private var metadataViewModel: RefreshMetadataViewModel

    init(viewModel: ItemViewModel) {
        self.viewModel = viewModel
        _metadataViewModel = StateObject(wrappedValue: RefreshMetadataViewModel(item: viewModel.item))
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .initial, .content, .refreshing:
                contentView
            case let .error(error):
                ErrorView(error: error)
            }
        }
        .navigationTitle(L10n.metadata)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarCloseButton {
            router.dismiss()
        }
        .refreshable {
            viewModel.send(.refresh)
        }
    }

    // MARK: - Content View

    private var contentView: some View {
        List {
            ListTitleSection(
                viewModel.item.name ?? L10n.unknown,
                description: viewModel.item.path
            )

            // MARK: Metadata

            Section(L10n.edit) {
                if let itemKind = viewModel.item.type,
                   BaseItemKind.itemIdentifiableCases.contains(itemKind)
                {
                    ChevronButton(L10n.identify) {
                        router.route(to: .identifyItem(item: viewModel.item))
                    }
                }

                ChevronButton(L10n.images) {
                    router.route(to: .itemImages(viewModel: ItemImagesViewModel(item: viewModel.item)))
                }

                ChevronButton(L10n.metadata) {
                    router.route(to: .editMetadata(item: viewModel.item))
                }
            }

            // MARK: Components

            if viewModel.item.hasComponents {
                Section {
                    ChevronButton(L10n.genres) {
                        router.route(to: .editGenres(item: viewModel.item))
                    }
                    ChevronButton(L10n.people) {
                        router.route(to: .editPeople(item: viewModel.item))
                    }
                    ChevronButton(L10n.tags) {
                        router.route(to: .editTags(item: viewModel.item))
                    }
                    ChevronButton(L10n.studios) {
                        router.route(to: .editStudios(item: viewModel.item))
                    }
                }
            }
        }
    }
}
