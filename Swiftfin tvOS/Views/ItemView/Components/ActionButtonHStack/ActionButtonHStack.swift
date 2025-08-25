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

        @StoredValue(.User.enableItemDeletion)
        private var enableItemDeletion: Bool
        @StoredValue(.User.enableItemEditing)
        private var enableItemEditing: Bool
        @StoredValue(.User.enableCollectionManagement)
        private var enableCollectionManagement: Bool
        @StoredValue(.User.enabledTrailers)
        private var enabledTrailers: TrailerSelection

        // MARK: - Observed, State, & Environment Objects

        @Router
        private var router

        @ObservedObject
        var viewModel: ItemViewModel

        @StateObject
        private var deleteViewModel: DeleteItemViewModel

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
            viewModel.userSession.user.permissions.items.canDelete(item: viewModel.item)
        }

        // MARK: - Can Refresh Item

        private var canRefresh: Bool {
            viewModel.userSession.user.permissions.items.canEditMetadata(item: viewModel.item)
        }

        // MARK: - Can Manage Subtitles

        private var canManageSubtitles: Bool {
            viewModel.userSession.user.permissions.items.canManageSubtitles(item: viewModel.item)
        }

        // MARK: - Deletion or Refreshing is Enabled

        private var enableMenu: Bool {
            canDelete || canRefresh
        }

        // MARK: - Has Trailers

        private var hasTrailers: Bool {
            if enabledTrailers.contains(.local), viewModel.localTrailers.isNotEmpty {
                return true
            }

            if enabledTrailers.contains(.external), viewModel.item.remoteTrailers?.isNotEmpty == true {
                return true
            }

            return false
        }

        // MARK: - Initializer

        init(viewModel: ItemViewModel) {
            self.viewModel = viewModel
            self._deleteViewModel = StateObject(wrappedValue: .init(item: viewModel.item))
        }

        // MARK: - Body

        var body: some View {
            HStack(alignment: .center, spacing: 30) {

                // MARK: Toggle Played

                if viewModel.item.canBePlayed {
                    let isCheckmarkSelected = viewModel.item.userData?.isPlayed == true

                    Button(L10n.played, systemImage: "checkmark") {
                        viewModel.send(.toggleIsPlayed)
                    }
                    .buttonStyle(.tintedMaterial(tint: Color.jellyfinPurple, foregroundColor: .primary))
                    .isSelected(isCheckmarkSelected)
                    .frame(minWidth: 100, maxWidth: .infinity)
                }

                // MARK: Toggle Favorite

                let isHeartSelected = viewModel.item.userData?.isFavorite == true

                Button(L10n.favorited, systemImage: isHeartSelected ? "heart.fill" : "heart") {
                    viewModel.send(.toggleIsFavorite)
                }
                .buttonStyle(.tintedMaterial(tint: .pink, foregroundColor: .primary))
                .isSelected(isHeartSelected)
                .frame(minWidth: 100, maxWidth: .infinity)

                // MARK: Watch a Trailer

                if hasTrailers {
                    TrailerMenu(
                        localTrailers: viewModel.localTrailers,
                        externalTrailers: viewModel.item.remoteTrailers ?? []
                    )
                    .buttonStyle(.tintedMaterial(tint: .pink, foregroundColor: .primary))
                    .frame(minWidth: 100, maxWidth: .infinity)
                }

                // MARK: Advanced Options

                if enableMenu {
                    Menu {
                        if canRefresh || canManageSubtitles {
                            Section(L10n.manage) {
                                if canRefresh {
                                    RefreshMetadataButton(item: viewModel.item)
                                }

                                if canManageSubtitles {
                                    Button(L10n.subtitles, systemImage: "textformat") {
                                        router.route(
                                            to: .searchSubtitle(
                                                viewModel: .init(item: viewModel.item)
                                            )
                                        )
                                    }
                                }
                            }
                        }

                        if canDelete {
                            Section {
                                Button(L10n.delete, systemImage: "trash", role: .destructive) {
                                    showConfirmationDialog = true
                                }
                            }
                        }
                    } label: {
                        Label(L10n.advanced, systemImage: "ellipsis")
                            .rotationEffect(.degrees(90))
                    }
                    .buttonStyle(.material)
                    .frame(width: 60, height: 100)
                }
            }
            .frame(height: 100)
            .labelStyle(.iconOnly)
            .font(.title3)
            .fontWeight(.semibold)
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
                    router.dismiss()
                }
            }
            .errorMessage($error)
        }
    }
}
