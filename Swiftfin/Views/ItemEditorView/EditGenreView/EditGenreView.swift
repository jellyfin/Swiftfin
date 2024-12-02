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
    private var router: ItemEditorCoordinator.Router

    @ObservedObject
    var viewModel: GenreEditorViewModel

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
            .navigationBarTitle(L10n.genres)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(isEditing)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if isEditing {
                        navigationBarSelectView
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
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
                    }
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
            .navigationBarMenuButton(
                isLoading: viewModel.backgroundStates.contains(.refreshing),
                isHidden: isEditing
            ) {
                Button(L10n.add, systemImage: "plus") {
                    router.route(to: \.addGenre, viewModel)
                }

                if viewModel.item.genres?.isNotEmpty == true {
                    Button(L10n.edit, systemImage: "checkmark.circle") {
                        isEditing = true
                    }
                }
            }
            .confirmationDialog(
                L10n.delete,
                isPresented: $isPresentingDeleteSelectionConfirmation,
                titleVisibility: .visible
            ) {
                deleteSelectedGenresConfirmationActions
            } message: {
                Text(L10n.deleteSelectedGenresConfirmation)
            }
            .confirmationDialog(
                L10n.delete,
                isPresented: $isPresentingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                deleteTagConfirmationActions
            } message: {
                Text(L10n.deleteGenreConfirmation)
            }
    }

    // MARK: - Navigation Bar Select/Remove All Content

    @ViewBuilder
    private var navigationBarSelectView: some View {
        let isAllSelected = selectedGenres.count == (viewModel.item.genres?.count ?? 0)
        Button(isAllSelected ? L10n.removeAll : L10n.selectAll) {
            selectedGenres = isAllSelected ? [] : Set(viewModel.item.genres ?? [])
        }
        .buttonStyle(.toolbarPill)
        .disabled(!isEditing)
        .foregroundStyle(accentColor)
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

            if let genres = viewModel.item.genres, !genres.isEmpty {
                ForEach(viewModel.item.genres ?? [], id: \.self) { genre in
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
            let genresToRemove = viewModel.item.genres?.filter { selectedGenres.contains($0) } ?? []
            viewModel.send(.remove(genresToRemove))
            selectedGenres.removeAll()
            isEditing = false
        }
    }

    // MARK: - Delete Single Genre Confirmation Actions

    @ViewBuilder
    private var deleteTagConfirmationActions: some View {
        Button(L10n.cancel, role: .cancel) {}

        Button(L10n.delete, role: .destructive) {
            if let genresToRemove = selectedGenres.first, selectedGenres.count == 1 {
                viewModel.send(.remove([genresToRemove]))
                selectedGenres.removeAll()
                isEditing = false
            }
        }
    }
}
