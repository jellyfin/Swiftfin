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

struct EditTagView: View {

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
    private var selectedTags: Set<String> = []
    @State
    private var isEditing: Bool = false

    // MARK: - Body

    @ViewBuilder
    var body: some View {
        contentView
            .navigationBarTitle(L10n.editWithItem(L10n.tags))
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
                        .disabled(selectedTags.isEmpty)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }
            .confirmationDialog(
                L10n.deleteSelectedTags,
                isPresented: $isPresentingDeleteSelectionConfirmation,
                titleVisibility: .visible
            ) {
                deleteSelectedTagsConfirmationActions
            } message: {
                Text(L10n.deleteSelectedTagsWarning)
            }
            .confirmationDialog(
                L10n.deleteTag,
                isPresented: $isPresentingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                deleteTagConfirmationActions
            } message: {
                Text(L10n.deleteTagWarning)
            }
    }

    // MARK: - Navigation Bar Select/Remove All Content

    @ViewBuilder
    private var navigationBarSelectView: some View {
        let isAllSelected = selectedTags.count == (viewModel.item.tags?.count ?? 0)
        Button(isAllSelected ? L10n.removeAll : L10n.selectAll) {
            selectedTags = isAllSelected ? [] : Set(viewModel.item.tags ?? [])
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
                    selectedTags.removeAll()
                }
            }
            .buttonStyle(.toolbarPill)
            .foregroundStyle(accentColor)
        } else {
            Menu(L10n.options, systemImage: "ellipsis.circle") {
                Button(L10n.addTag, systemImage: "plus") {
                    router.route(to: \.addTag, viewModel)
                }

                if viewModel.item.tags?.isNotEmpty == true {
                    Button(L10n.editTags, systemImage: "checkmark.circle") {
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
                L10n.tags,
                description: L10n.tagsDescription
            )
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .padding(.vertical, 24)

            if let tags = viewModel.item.tags, !tags.isEmpty {
                ForEach(viewModel.item.tags ?? [], id: \.self) { tag in
                    EditTagRow(tag: tag) {
                        if isEditing {
                            selectedTags.toggle(value: tag)
                        }
                    } onDelete: {
                        selectedTags = [tag]
                        isPresentingDeleteConfirmation = true
                    }
                    .environment(\.isEditing, isEditing)
                    .environment(\.isSelected, selectedTags.contains(tag))
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

    // MARK: - Delete Selected Tags Confirmation Actions

    @ViewBuilder
    private var deleteSelectedTagsConfirmationActions: some View {
        Button(L10n.cancel, role: .cancel) {}

        Button(L10n.confirm, role: .destructive) {
            let tagsToRemove = viewModel.item.tags?.filter { selectedTags.contains($0) } ?? []
            viewModel.send(.removeTags(tagsToRemove))
            selectedTags.removeAll()
            isEditing = false
        }
    }

    // MARK: - Delete Single Tag Confirmation Actions

    @ViewBuilder
    private var deleteTagConfirmationActions: some View {
        Button(L10n.cancel, role: .cancel) {}

        Button(L10n.delete, role: .destructive) {
            if let tagToDelete = selectedTags.first, selectedTags.count == 1 {
                viewModel.send(.removeTags([tagToDelete]))
                selectedTags.removeAll()
                isEditing = false
            }
        }
    }
}
