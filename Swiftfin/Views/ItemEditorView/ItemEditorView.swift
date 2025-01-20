//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Factory
import JellyfinAPI
import SwiftUI

struct ItemEditorView: View {

    @Injected(\.currentUserSession)
    private var userSession

    @EnvironmentObject
    private var router: ItemEditorCoordinator.Router

    @ObservedObject
    var viewModel: ItemViewModel

    // MARK: - Body

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .initial, .content, .refreshing:
                contentView
            case let .error(error):
                errorView(with: error)
            }
        }
        .navigationBarTitle(L10n.metadata)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarCloseButton {
            router.dismissCoordinator()
        }
    }

    // MARK: - Content View

    private var contentView: some View {
        List {
            ListTitleSection(
                viewModel.item.name ?? L10n.unknown,
                description: viewModel.item.path
            )

            refreshButtonView

            editView
        }
    }

    // MARK: - ErrorView

    @ViewBuilder
    private func errorView(with error: some Error) -> some View {
        ErrorView(error: error)
            .onRetry {
                viewModel.send(.refresh)
            }
    }

    // MARK: - Refresh Menu Button

    @ViewBuilder
    private var refreshButtonView: some View {
        Section {
            RefreshMetadataButton(item: viewModel.item)
                .environment(\.isEnabled, userSession?.user.permissions.isAdministrator ?? false)
        } footer: {
            LearnMoreButton(L10n.metadata) {
                TextPair(
                    title: L10n.findMissing,
                    subtitle: L10n.findMissingDescription
                )
                TextPair(
                    title: L10n.replaceMetadata,
                    subtitle: L10n.replaceMetadataDescription
                )
                TextPair(
                    title: L10n.replaceImages,
                    subtitle: L10n.replaceImagesDescription
                )
                TextPair(
                    title: L10n.replaceAll,
                    subtitle: L10n.replaceAllDescription
                )
            }
        }
    }

    // MARK: - Editable Routing Buttons

    @ViewBuilder
    private var editView: some View {
        Section(L10n.edit) {
            if [.boxSet, .movie, .person, .series].contains(viewModel.item.type) {
                ChevronButton(L10n.identify)
                    .onSelect {
                        router.route(to: \.identifyItem, viewModel.item)
                    }
            }
            ChevronButton(L10n.images)
                .onSelect {
                    router.route(to: \.editImages, ItemImagesViewModel(item: viewModel.item))
                }
            ChevronButton(L10n.metadata)
                .onSelect {
                    router.route(to: \.editMetadata, viewModel.item)
                }
        }

        Section {
            ChevronButton(L10n.genres)
                .onSelect {
                    router.route(to: \.editGenres, viewModel.item)
                }
            ChevronButton(L10n.people)
                .onSelect {
                    router.route(to: \.editPeople, viewModel.item)
                }
            ChevronButton(L10n.tags)
                .onSelect {
                    router.route(to: \.editTags, viewModel.item)
                }
            ChevronButton(L10n.studios)
                .onSelect {
                    router.route(to: \.editStudios, viewModel.item)
                }
        }
    }
}
