//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
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

        @Router
        private var router

        @ObservedObject
        var viewModel: ItemViewModel

        @StateObject
        private var deleteViewModel: DeleteItemViewModel

        @State
        private var showConfirmationDialog = false
        @State
        private var isPresentingEventAlert = false

        @State
        private var error: Error?

        private var canDelete: Bool {
            viewModel.userSession.user.permissions.items.canDelete(item: viewModel.item)
        }

        private var canRefresh: Bool {
            viewModel.userSession.user.permissions.items.canEditMetadata(item: viewModel.item)
        }

        private var canManageSubtitles: Bool {
            viewModel.userSession.user.permissions.items.canManageSubtitles(item: viewModel.item)
        }

        private var enableMenu: Bool {
            canDelete || canRefresh || viewModel.item.canShuffle
        }

        private var hasTrailers: Bool {
            if enabledTrailers.contains(.local), viewModel.localTrailers.isNotEmpty {
                return true
            }

            if enabledTrailers.contains(.external), viewModel.item.remoteTrailers?.isNotEmpty == true {
                return true
            }

            return false
        }

        init(viewModel: ItemViewModel) {
            self.viewModel = viewModel
            self._deleteViewModel = StateObject(wrappedValue: .init(item: viewModel.item))
        }

        var body: some View {
            HStack(alignment: .center, spacing: 20) {

                if viewModel.item.canBePlayed {
                    let isCheckmarkSelected = viewModel.item.userData?.isPlayed == true

                    ActionButton(
                        L10n.played,
                        icon: "checkmark.circle",
                        selectedIcon: "checkmark.circle.fill"
                    ) {
                        viewModel.send(.toggleIsPlayed)
                    }
                    .foregroundStyle(Color.jellyfinPurple)
                    .isSelected(isCheckmarkSelected)
                    .frame(minWidth: 100, maxWidth: .infinity)
                }

                let isHeartSelected = viewModel.item.userData?.isFavorite == true

                ActionButton(
                    L10n.favorited,
                    icon: "heart.circle",
                    selectedIcon: "heart.circle.fill"
                ) {
                    viewModel.send(.toggleIsFavorite)
                }
                .foregroundStyle(.pink)
                .isSelected(isHeartSelected)
                .frame(minWidth: 100, maxWidth: .infinity)

                if hasTrailers {
                    TrailerMenu(
                        localTrailers: viewModel.localTrailers,
                        externalTrailers: viewModel.item.remoteTrailers ?? []
                    )
                }

                if enableMenu {
                    ActionButton(L10n.advanced, icon: "ellipsis", isCompact: true) {
                        if viewModel.item.canShuffle {
                            Section {
                                Button(L10n.shuffle, systemImage: "shuffle") {
                                    viewModel.playShuffle(router: router.router)
                                }
                            }
                        }

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
                    }
                    .frame(width: 60)
                }
            }
            .frame(height: 100)
            .padding(.top, 1)
            .padding(.bottom, 10)
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
