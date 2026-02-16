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

    // MARK: - Router

    @Router
    private var router

    // MARK: - ViewModel

    @ObservedObject
    var viewModel: ItemViewModel

    @StateObject
    private var metadataViewModel: RefreshMetadataViewModel

    private var canEditMetadata: Bool {
        viewModel.userSession.user.permissions.items.canEditMetadata(item: viewModel.item) == true
    }

    private var canManageSubtitles: Bool {
        viewModel.userSession.user.permissions.items.canManageSubtitles(item: viewModel.item) == true
    }

    private var canManageLyrics: Bool {
        viewModel.userSession.user.permissions.items.canManageLyrics(item: viewModel.item) == true
    }

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

            // Hide metadata options to Lyric/Subtitle only users
            if canEditMetadata {

                refreshButtonView

                Section(L10n.edit) {
                    editMetadataView
                    editTextView
                }

                if viewModel.item.hasComponents {
                    editComponentsView
                }
            } /*  else if canManageSubtitles || canManageLyrics {

                 // TODO: Enable when Subtitle / Lyric Editing is added
                 Section(L10n.edit) {
                     editTextView
                 }
             }*/
        }
    }

    // MARK: - Refresh Button

    private var refreshButtonView: some View {
        Section {
            Button {
                router.route(to: .itemMetadataRefresh(viewModel: metadataViewModel))
            } label: {
                HStack {
                    Text(L10n.refreshMetadata)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(.primary)

                    if metadataViewModel.state == .refreshing {
                        ProgressView(value: metadataViewModel.progress)
                            .progressViewStyle(.gauge)
                            .transition(.opacity.combined(with: .scale).animation(.bouncy))
                            .frame(width: 25, height: 25)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(.secondary)
                            .fontWeight(.semibold)
                    }
                }
            }
            .foregroundStyle(.primary, .secondary)
            .disabled(metadataViewModel.state == .refreshing)
        }
    }

    // MARK: - Editable Metadata Routing Buttons

    @ViewBuilder
    private var editMetadataView: some View {

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

    // MARK: - Editable Text Routing Buttons

    @ViewBuilder
    private var editTextView: some View {
        if canManageSubtitles {
            ChevronButton(L10n.subtitles) {
                router.route(to: .editSubtitles(item: viewModel.item))
            }
        }
        if canManageLyrics {
//          ChevronButton(L10n.lyrics) {
//              router.route(to: \.editLyrics, viewModel.item)
//          }
        }
    }

    // MARK: - Editable Metadata Components Routing Buttons

    private var editComponentsView: some View {
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
