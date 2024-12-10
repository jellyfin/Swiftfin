//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ItemView {

    struct ActionButtonHStack: View {

        // MARK: - Environment Objects

        @EnvironmentObject
        private var router: ItemCoordinator.Router

        // MARK: - View Models

        @ObservedObject
        var viewModel: ItemViewModel
        @StateObject
        var deleteViewModel: DeleteItemViewModel

        // MARK: - User Settings

        @StoredValue(.User.enableItemDeletion)
        private var enableItemDeletion: Bool
        @StoredValue(.User.enableItemEditing)
        private var enableItemEditing: Bool
        @StoredValue(.User.enableCollectionManagement)
        private var enableCollectionManagement: Bool

        // MARK: - Alert / Dialog States

        @State
        private var showConfirmationDialog = false
        @State
        private var isPresentingEventAlert = false
        @State
        private var error: JellyfinAPIError?

        // MARK: - Determine Permissions from Item & User Settings

        private var canDelete: Bool {
            if viewModel.item.type == .boxSet {
                return enableCollectionManagement && viewModel.item.canDelete ?? false
            } else {
                return enableItemDeletion && viewModel.item.canDelete ?? false
            }
        }

        private var canRefresh: Bool {
            if viewModel.item.type == .boxSet {
                return enableCollectionManagement
            } else {
                return enableItemEditing
            }
        }

        // MARK: - Initializer

        init(viewModel: ItemViewModel) {
            self.viewModel = viewModel
            self._deleteViewModel = StateObject(wrappedValue: .init(item: viewModel.item))
        }

        // MARK: - Body

        /// Shrink to minWidth 100 (button) / 50 (menu) and 16 spacing to get 3 buttons + menu
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
                .frame(minWidth: 140, maxWidth: .infinity)

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
                .frame(minWidth: 140, maxWidth: .infinity)

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
                    .frame(width: 70)
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
                    isPresentingEventAlert = true
                case .deleted:
                    router.dismissCoordinator()
                }
            }
            .alert(
                L10n.error,
                isPresented: $isPresentingEventAlert,
                presenting: error
            ) { _ in
            } message: { error in
                Text(error.localizedDescription)
            }
        }
    }
}
