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

    @EnvironmentObject
    private var router: ItemEditorCoordinator.Router

    @ObservedObject
    var viewModel: ItemViewModel

    // MARK: - Can Edit Metadata

    private var canEditMetadata: Bool {
        viewModel.userSession.user.permissions.items.canEditMetadata(item: viewModel.item) == true
    }

    // MARK: - Can Manage Subtitles

    private var canManageSubtitles: Bool {
        viewModel.userSession.user.permissions.items.canManageSubtitles(item: viewModel.item) == true
    }

    // MARK: - Can Manage Lyrics

    private var canManageLyrics: Bool {
        viewModel.userSession.user.permissions.items.canManageLyrics(item: viewModel.item) == true
    }

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

            /// Hide metadata options to Lyric/Subtitle only users
            if canEditMetadata {

                refreshButtonView

                Section(L10n.edit) {
                    editMetadataView
                    editTextView
                }

                editComponentsView
            } /*  else if canManageSubtitles || canManageLyrics {

                 // TODO: Enable when Subtitle / Lyric Editing is added
                 Section(L10n.edit) {
                     editTextView
                 }
             }*/
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

    // MARK: - Editable Metadata Routing Buttons

    @ViewBuilder
    private var editMetadataView: some View {

        if let itemKind = viewModel.item.type,
           BaseItemKind.itemIdentifiableCases.contains(itemKind)
        {
            ChevronButton(L10n.identify) {
                router.route(to: \.identifyItem, viewModel.item)
            }
        }
        ChevronButton(L10n.images) {
            router.route(to: \.editImages, ItemImagesViewModel(item: viewModel.item))
        }
        ChevronButton(L10n.metadata) {
            router.route(to: \.editMetadata, viewModel.item)
        }
    }

    // MARK: - Editable Text Routing Buttons

    @ViewBuilder
    private var editTextView: some View {
        if canManageLyrics {
//          ChevronButton(L10n.lyrics) {
//              router.route(to: \.editImages, ItemImagesViewModel(item: viewModel.item))
//          }
        }
        if canManageSubtitles {
//          ChevronButton(L10n.subtitles) {
//              router.route(to: \.editImages, ItemImagesViewModel(item: viewModel.item))
//          }
        }
    }

    // MARK: - Editable Metadata Components Routing Buttons

    @ViewBuilder
    private var editComponentsView: some View {
        Section {
            ChevronButton(L10n.genres) {
                router.route(to: \.editGenres, viewModel.item)
            }
            ChevronButton(L10n.people) {
                router.route(to: \.editPeople, viewModel.item)
            }
            ChevronButton(L10n.tags) {
                router.route(to: \.editTags, viewModel.item)
            }
            ChevronButton(L10n.studios) {
                router.route(to: \.editStudios, viewModel.item)
            }
        }
    }
}
