//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ItemView {

    struct ActionButtonHStack: View {

        // MARK: - Observed, State, & Environment Objects

        @EnvironmentObject
        private var router: ItemCoordinator.Router

        @ObservedObject
        var viewModel: ItemViewModel

        @StateObject
        var deleteViewModel: DeleteItemViewModel

        // MARK: - Defaults

        @StoredValue(.User.enableItemDeletion)
        private var enableItemDeletion: Bool
        @StoredValue(.User.enableItemEditing)
        private var enableItemEditing: Bool
        @StoredValue(.User.enableCollectionManagement)
        private var enableCollectionManagement: Bool

        // MARK: - Dialog States

        @State
        private var showConfirmationDialog = false
        @State
        private var isPresentingEventAlert = false

        // MARK: - Error State

        @State
        private var error: Error?

        // MARK: - Can Delete Item

        private var canDelete: Bool {
            if viewModel.item.type == .boxSet {
                return enableCollectionManagement && viewModel.item.canDelete ?? false
            } else {
                return enableItemDeletion && viewModel.item.canDelete ?? false
            }
        }

        // MARK: - Refresh Item

        private var canRefresh: Bool {
            if viewModel.item.type == .boxSet {
                return enableCollectionManagement
            } else {
                return enableItemEditing
            }
        }

        // MARK: - Select Item(s)

        private var hasMultipleVersions: Bool {
            guard let mediaSources = viewModel.playButtonItem?.mediaSources else { return false }
            return mediaSources.count > 1
        }

        // MARK: - Initializer

        init(viewModel: ItemViewModel) {
            self.viewModel = viewModel
            self._deleteViewModel = StateObject(wrappedValue: .init(item: viewModel.item))
        }

        // MARK: - Body

        var body: some View {
            HStack(alignment: .center, spacing: 24) {

                // MARK: - Toggle Played

                ActionButton(
                    title: L10n.played,
                    icon: "checkmark.circle",
                    selectedIcon: "checkmark.circle.fill"
                ) {
                    viewModel.send(.toggleIsPlayed)
                }
                .foregroundStyle(.purple)
                .environment(\.isSelected, viewModel.item.userData?.isPlayed ?? false)
                .frame(minWidth: 80, maxWidth: .infinity)

                // MARK: - Toggle Favorite

                ActionButton(
                    title: L10n.favorited,
                    icon: "heart.circle",
                    selectedIcon: "heart.circle.fill"
                ) {
                    viewModel.send(.toggleIsFavorite)
                }
                .foregroundStyle(.pink)
                .environment(\.isSelected, viewModel.item.userData?.isFavorite ?? false)
                .frame(minWidth: 80, maxWidth: .infinity)

                // MARK: - Select Merged Version

                if multipleVersions {
                    VersionMenu(viewModel: viewModel)
                        .frame(minWidth: 80, maxWidth: .infinity)
                }

                // MARK: - Additional Menu Options

                if canRefresh || canDelete {
                    ActionMenu {
                        if canRefresh {
                            RefreshMetadataButton(item: viewModel.item)
                        }

                        if canDelete {
                            Divider()
                            Button(L10n.delete, systemImage: "trash", role: .destructive) {
                                showConfirmationDialog = true
                            }
                        }
                    }
                    .frame(width: 40)
                }
            }
            .frame(height: 100)
            .confirmationDialog(
                L10n.deleteItemConfirmationMessage,
                isPresented: $showConfirmationDialog,
                titleVisibility: .visible
            ) {
                Button(L10n.confirm, role: .destructive) {
                    deleteViewModel.send(.delete)
                }
                Button(L10n.cancel, role: .cancel) {}
            }
            .onReceive(deleteViewModel.events) { event in
                switch event {
                case let .error(eventError):
                    error = eventError
                case .deleted:
                    router.dismissCoordinator()
                }
            }
            .errorMessage($error)
        }
    }
}
