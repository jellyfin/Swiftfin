//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import JellyfinAPI
import SwiftUI

struct EditGenreView: View {

    @Default(.accentColor)
    private var accentColor

    @EnvironmentObject
    private var router: ItemDetailsCoordinator.Router

    @ObservedObject
    var viewModel: ItemDetailsViewModel

    @State
    private var isPresentingDeleteConfirmation = false
    @State
    private var isPresentingDeleteSelectionConfirmation = false
    @State
    private var selectedGenres: Set<String> = []
    @State
    private var isEditing: Bool = false

    // MARK: - Body

    @ViewBuilder
    var body: some View {
        contentView
            .navigationBarTitle(L10n.editWithItem(L10n.genres))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(isEditing)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if isEditing {
                        navigationBarSelectView
                    }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    navigationBarEditView
                }
                ToolbarItem(placement: .bottomBar) {
                    if isEditing {
                        Button(L10n.delete) {
                            isPresentingDeleteSelectionConfirmation = true
                        }
                        .buttonStyle(.toolbarPill(.red))
                        .disabled(selectedGenres.isEmpty)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }
            .confirmationDialog(
                L10n.deleteSelectedGenres,
                isPresented: $isPresentingDeleteSelectionConfirmation,
                titleVisibility: .visible
            ) {
                deleteSelectedGenresConfirmationActions
            } message: {
                Text(L10n.deleteSelectedGenresWarning)
            }
            .confirmationDialog(
                L10n.deleteGenre,
                isPresented: $isPresentingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                deleteGenreConfirmationActions
            } message: {
                Text(L10n.deleteGenreWarning)
            }
    }

    // MARK: - Navigation Bar Select/Remove All Content

    @ViewBuilder
    private var navigationBarSelectView: some View {
        let isAllSelected = selectedGenres.count == viewModel.genres.count
        Button(isAllSelected ? L10n.removeAll : L10n.selectAll) {
            selectedGenres = isAllSelected ? [] : Set(viewModel.genres)
        }
        .buttonStyle(.toolbarPill)
        .disabled(!isEditing)
        .foregroundStyle(accentColor)
    }

    // MARK: - Navigation Bar Edit Content

    @ViewBuilder
    private var navigationBarEditView: some View {
        if viewModel.state == .refreshing {
            ProgressView()
        }

        if isEditing {
            Button(L10n.cancel) {
                isEditing.toggle()
                UIDevice.impact(.light)
                if !isEditing {
                    selectedGenres.removeAll()
                }
            }
            .buttonStyle(.toolbarPill)
            .foregroundStyle(accentColor)
        } else {
            Menu(L10n.options, systemImage: "ellipsis.circle") {
                Button(L10n.addGenre, systemImage: "plus") {
                    router.route(to: \.addGenre, viewModel)
                }

                if viewModel.genres.isNotEmpty {
                    Button(L10n.editGenres, systemImage: "checkmark.circle") {
                        isEditing = true
                    }
                }
            }
            .labelStyle(.iconOnly)
            .backport
            .fontWeight(.semibold)
        }
    }

    // MARK: - Content View

    private var contentView: some View {
        List {
            InsetGroupedListHeader(
                L10n.genres,
                description: L10n.genresDescription
            )
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .padding(.vertical, 24)

            if viewModel.genres.isNotEmpty {
                ForEach(viewModel.genres, id: \.self) { genre in
                    EditGenreRow(genre: genre) {
                        if isEditing {
                            selectedGenres.toggle(value: genre)
                        }
                    } onDelete: {
                        selectedGenres = [genre]
                        isPresentingDeleteConfirmation = true
                    }
                    .environment(\.isEditing, isEditing)
                    .environment(\.isSelected, selectedGenres.contains(genre))
                    .listRowSeparator(.hidden)
                    .listRowInsets(.zero)
                }
            } else {
                Text(L10n.none)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .listRowSeparator(.hidden)
                    .listRowInsets(.zero)
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Delete Selected Genres Confirmation Actions

    @ViewBuilder
    private var deleteSelectedGenresConfirmationActions: some View {
        Button(L10n.cancel, role: .cancel) {}

        Button(L10n.confirm, role: .destructive) {
            let genresToRemove = viewModel.genres.filter { selectedGenres.contains($0) }
            viewModel.send(.removeGenres(genresToRemove))
            selectedGenres.removeAll()
            isEditing = false
        }
    }

    // MARK: - Delete Single Genre Confirmation Actions

    @ViewBuilder
    private var deleteGenreConfirmationActions: some View {
        Button(L10n.cancel, role: .cancel) {}

        Button(L10n.delete, role: .destructive) {
            if let genreToDelete = selectedGenres.first, selectedGenres.count == 1 {
                viewModel.send(.removeGenres([genreToDelete]))
                selectedGenres.removeAll()
                isEditing = false
            }
        }
    }
}
