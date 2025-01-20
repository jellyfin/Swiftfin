//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

struct EditServerUserAccessTagsView: View {

    private struct TagWithAccess: Hashable {
        let tag: String
        let access: Bool
    }

    // MARK: - Observed, State, & Environment Objects

    @EnvironmentObject
    private var router: AdminDashboardCoordinator.Router

    @StateObject
    private var viewModel: ServerUserAdminViewModel

    // MARK: - Dialog States

    @State
    private var isPresentingDeleteConfirmation = false

    // MARK: - Editing States

    @State
    private var selectedTags: Set<TagWithAccess> = []
    @State
    private var isEditing: Bool = false

    // MARK: - Error State

    @State
    private var error: Error?

    private var blockedTags: [TagWithAccess] {
        viewModel.user.policy?.blockedTags?
            .sorted()
            .map { TagWithAccess(tag: $0, access: false) } ?? []
    }

//    private var allowedTags: [TagWithAccess] {
//        viewModel.user.policy?.allowedTags?
//            .sorted()
//            .map { TagWithAccess(tag: $0, access: true) } ?? []
//    }

    // MARK: - Initializera

    init(viewModel: ServerUserAdminViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .initial, .content:
                contentView
            case let .error(error):
                errorView(with: error)
            }
        }
        .navigationTitle(L10n.accessTags)
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
            isLoading: viewModel.backgroundStates.contains(.refreshing),
            isHidden: isEditing || (
                viewModel.user.policy?.blockedTags?.isEmpty == true
            )
        ) {
            Button(L10n.add, systemImage: "plus") {
                router.route(to: \.userAddAccessTag, viewModel)
            }

            if viewModel.user.policy?.blockedTags?.isNotEmpty == true {
                Button(L10n.edit, systemImage: "checkmark.circle") {
                    isEditing = true
                }
            }
        }
        .onReceive(viewModel.events) { event in
            switch event {
            case let .error(eventError):
                error = eventError
            default:
                break
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
        .errorMessage($error)
    }

    // MARK: - ErrorView

    @ViewBuilder
    private func errorView(with error: some Error) -> some View {
        ErrorView(error: error)
            .onRetry {
                viewModel.send(.refresh)
            }
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
        .environment(\.isEditing, isEditing)
        .environment(\.isSelected, selectedTags.contains(tag))
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        List {
            ListTitleSection(
                L10n.accessTags,
                description: L10n.accessTagsDescription
            ) {
                UIApplication.shared.open(.jellyfinDocsManagingUsers)
            }

            if blockedTags.isEmpty {
                Button(L10n.add) {
                    router.route(to: \.userAddAccessTag, viewModel)
                }
            } else {

                // TODO: with allowed, use `DisclosureGroup` instead
                Section(L10n.blocked) {
                    ForEach(
                        blockedTags,
                        id: \.self,
                        content: makeRow
                    )
                }

                // TODO: allowed with 10.10
            }
        }
    }

    // MARK: - Select/Remove All Button

    @ViewBuilder
    private var navigationBarSelectView: some View {
        let isAllSelected = selectedTags.count == blockedTags.count

        Button(isAllSelected ? L10n.removeAll : L10n.selectAll) {
            selectedTags = isAllSelected ? [] : Set(blockedTags)
        }
        .buttonStyle(.toolbarPill)
        .disabled(!isEditing)
    }

    // MARK: - Delete Selected Confirmation Actions

    @ViewBuilder
    private var deleteSelectedConfirmationActions: some View {
        Button(L10n.cancel, role: .cancel) {}

        Button(L10n.delete, role: .destructive) {
            var tempPolicy = viewModel.user.policy ?? UserPolicy()

            for tag in selectedTags {
                if tag.access {
                    // tempPolicy.allowedTags?.removeAll { $0 == tag.tag }
                } else {
                    tempPolicy.blockedTags?.removeAll { $0 == tag.tag }
                }
            }

            viewModel.send(.updatePolicy(tempPolicy))
            selectedTags.removeAll()
            isEditing = false
        }
    }
}
