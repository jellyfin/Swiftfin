//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

struct EditServerUserAccessTagsView: View {

    private struct TagWithAccess: Hashable {
        let tag: String
        let access: Bool
    }

    @Router
    private var router

    @StateObject
    private var viewModel: ServerUserAdminViewModel

    @State
    private var isPresentingDeleteConfirmation = false
    @State
    private var selectedTags: Set<TagWithAccess> = []
    @State
    private var isEditing: Bool = false

    private var hasTags: Bool {
        viewModel.user.policy?.blockedTags?.isEmpty == true &&
            viewModel.user.policy?.allowedTags?.isEmpty == true
    }

    private var allowedTags: [TagWithAccess] {
        viewModel.user.policy?.allowedTags?
            .sorted()
            .map { TagWithAccess(tag: $0, access: true) } ?? []
    }

    private var blockedTags: [TagWithAccess] {
        viewModel.user.policy?.blockedTags?
            .sorted()
            .map { TagWithAccess(tag: $0, access: false) } ?? []
    }

    init(viewModel: ServerUserAdminViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .initial, .content:
                contentView
            case .error:
                viewModel.error.map {
                    ErrorView(error: $0)
                }
            }
        }
        .navigationTitle(L10n.accessTags.localizedCapitalized)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(isEditing)
        .refreshable {
            viewModel.refresh()
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if isEditing {
                    navigationBarSelectView
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                if isEditing {
                    Button(L10n.cancel) {
                        isEditing = false
                        UIDevice.impact(.light)
                        selectedTags.removeAll()
                    }
                    .buttonStyle(.toolbarPill)
                }
            }
            ToolbarItem(placement: .bottomBar) {
                if isEditing {
                    Button(L10n.delete) {
                        isPresentingDeleteConfirmation = true
                    }
                    .buttonStyle(.toolbarPill(.red))
                    .disabled(selectedTags.isEmpty)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
        .navigationBarMenuButton(
            isLoading: viewModel.background.is(.refreshing),
            isHidden: isEditing || hasTags
        ) {
            Button(L10n.add, systemImage: "plus") {
                router.route(to: .userAddAccessTag(viewModel: viewModel))
            }

            Button(L10n.edit, systemImage: "checkmark.circle") {
                isEditing = true
            }
        }
        .confirmationDialog(
            L10n.delete,
            isPresented: $isPresentingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            deleteSelectedConfirmationActions
        } message: {
            Text(L10n.deleteSelectedConfirmation)
        }
        .errorMessage($viewModel.error)
    }

    @ViewBuilder
    private func makeRow(tag: TagWithAccess) -> some View {
        EditAccessTagRow(tag: tag.tag) {
            if isEditing {
                selectedTags.toggle(value: tag)
            }
        } onDelete: {
            selectedTags = [tag]
            isPresentingDeleteConfirmation = true
        }
        .isEditing(isEditing)
        .isSelected(selectedTags.contains(tag))
    }

    @ViewBuilder
    private var contentView: some View {
        List {
            ListTitleSection(
                L10n.accessTags.localizedCapitalized,
                description: L10n.accessTagsDescription
            ) {
                UIApplication.shared.open(.jellyfinDocsManagingUsers)
            }

            if blockedTags.isEmpty, allowedTags.isEmpty {
                Button(L10n.add) {
                    router.route(to: .userAddAccessTag(viewModel: viewModel))
                }
            } else {
                if allowedTags.isNotEmpty {
                    Section {
                        DisclosureGroup(L10n.allowed) {
                            ForEach(
                                allowedTags,
                                id: \.self,
                                content: makeRow
                            )
                        }
                    }
                }
                if blockedTags.isNotEmpty {
                    Section {
                        DisclosureGroup(L10n.blocked) {
                            ForEach(
                                blockedTags,
                                id: \.self,
                                content: makeRow
                            )
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var navigationBarSelectView: some View {
        let isAllSelected = selectedTags.count == blockedTags.count + allowedTags.count

        Button(isAllSelected ? L10n.removeAll : L10n.selectAll) {
            selectedTags = isAllSelected ? [] : Set(blockedTags + allowedTags)
        }
        .buttonStyle(.toolbarPill)
        .disabled(!isEditing)
    }

    @ViewBuilder
    private var deleteSelectedConfirmationActions: some View {
        Button(L10n.cancel, role: .cancel) {}

        Button(L10n.delete, role: .destructive) {
            guard let policy = viewModel.user.policy else {
                preconditionFailure("User policy cannot be empty.")
            }

            var tempPolicy = policy

            for tag in selectedTags {
                if tag.access {
                    tempPolicy.allowedTags?.removeAll(equalTo: tag.tag)
                } else {
                    tempPolicy.blockedTags?.removeAll(equalTo: tag.tag)
                }
            }

            viewModel.updatePolicy(tempPolicy)
            selectedTags.removeAll()
            isEditing = false
        }
    }
}
