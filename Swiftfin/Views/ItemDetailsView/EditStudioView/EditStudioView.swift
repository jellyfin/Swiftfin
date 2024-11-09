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

struct EditStudioView: View {

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
    private var selectedStudios: Set<String> = []
    @State
    private var isEditing: Bool = false

    // MARK: - Body

    @ViewBuilder
    var body: some View {
        contentView
            .navigationBarTitle(L10n.editWithItem(L10n.studios))
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
                        .disabled(selectedStudios.isEmpty)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }
            .confirmationDialog(
                L10n.deleteSelectedStudios,
                isPresented: $isPresentingDeleteSelectionConfirmation,
                titleVisibility: .visible
            ) {
                deleteSelectedStudiosConfirmationActions
            } message: {
                Text(L10n.deleteSelectedStudiosWarning)
            }
            .confirmationDialog(
                L10n.deleteStudio,
                isPresented: $isPresentingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                deleteStudioConfirmationActions
            } message: {
                Text(L10n.deleteStudioWarning)
            }
    }

    // MARK: - Navigation Bar Select/Remove All Content

    @ViewBuilder
    private var navigationBarSelectView: some View {
        let isAllSelected = selectedStudios.count == (viewModel.item.studios?.count ?? 0)
        Button(isAllSelected ? L10n.removeAll : L10n.selectAll) {
            selectedStudios = isAllSelected ? [] : Set(viewModel.item.studios?.compactMap(\.id) ?? [])
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
                selectedStudios.removeAll()
            }
            .buttonStyle(.toolbarPill)
            .foregroundStyle(accentColor)
        } else {
            Menu(L10n.options, systemImage: "ellipsis.circle") {
                Button(L10n.addStudio, systemImage: "plus") {
                    router.route(to: \.addStudio, viewModel)
                }

                if viewModel.item.studios?.isNotEmpty == true {
                    Button(L10n.editStudios, systemImage: "checkmark.circle") {
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
                L10n.studios,
                description: L10n.studiosDescription
            )
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .padding(.vertical, 24)

            if let studios = viewModel.item.studios, !studios.isEmpty {
                ForEach(viewModel.item.studios ?? [], id: \.self) { studio in
                    if let studioID = studio.id {
                        EditStudioRow(studio: studio) {
                            if isEditing {
                                selectedStudios.toggle(value: studioID)
                            }
                        } onDelete: {
                            selectedStudios = [studioID]
                            isPresentingDeleteConfirmation = true
                        }
                        .environment(\.isEditing, isEditing)
                        .environment(\.isSelected, selectedStudios.contains(studioID))
                        .listRowSeparator(.hidden)
                        .listRowInsets(.zero)
                    }
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

    // MARK: - Delete Selected Studios Confirmation Actions

    @ViewBuilder
    private var deleteSelectedStudiosConfirmationActions: some View {
        Button(L10n.cancel, role: .cancel) {}

        Button(L10n.confirm, role: .destructive) {
            let studiosToRemove = viewModel.item.studios?.filter { selectedStudios.contains($0.id ?? "") } ?? []
            viewModel.send(.removeStudios(studiosToRemove))
            selectedStudios.removeAll()
            isEditing = false
        }
    }

    // MARK: - Delete Single Studio Confirmation Actions

    @ViewBuilder
    private var deleteStudioConfirmationActions: some View {
        Button(L10n.cancel, role: .cancel) {}

        Button(L10n.delete, role: .destructive) {
            if let studioToDelete = selectedStudios.first, selectedStudios.count == 1 {
                if let studio = viewModel.item.studios?.first(where: { $0.id == studioToDelete }) {
                    viewModel.send(.removeStudios([studio]))
                }
                selectedStudios.removeAll()
                isEditing = false
            }
        }
    }
}
