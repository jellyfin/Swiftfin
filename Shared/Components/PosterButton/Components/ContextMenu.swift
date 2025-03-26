//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Factory
import JellyfinAPI
import SwiftUI

extension PosterButton {

    struct ItemContextMenu: View {

        // MARK: - Current User Session

        @Injected(\.currentUserSession)
        private var userSession

        @EnvironmentObject
        private var mainRouter: MainCoordinator.Router

        // MARK: - PosterButton ContextMenu Variables

        private let item: BaseItemDto

        // MARK: - State Object Variables

        @StateObject
        private var itemViewModel: ItemViewModel
        @StateObject
        private var refreshViewModel: RefreshMetadataViewModel
        @StateObject
        private var deleteViewModel: DeleteItemViewModel

        // MARK: - Is The BaseItemDto Playable?

        private var isPlayable: Bool {
            item.type == .episode ||
                item.type == .movie ||
                item.type == .series ||
                item.type == .season ||
                item.type == .collectionFolder ||
                item.type == .boxSet ||
                item.type == .playlist ||
                item.type == .playlistsFolder
        }

        // MARK: - Initializer

        init(_ item: BaseItemDto) {
            self.item = item
            self._itemViewModel = .init(wrappedValue: .init(item: item))
            self._refreshViewModel = .init(wrappedValue: .init(item: item))
            self._deleteViewModel = .init(wrappedValue: .init(item: item))
        }

        // MARK: - Body

        var body: some View {
            playbackButtons
            actionButtons
            managementButtons
        }

        // MARK: - Playback Buttons

        @ViewBuilder
        private var playbackButtons: some View {
            if isPlayable {
                Section(L10n.media) {
                    /// Play / Resume
                    ContextMenuButton(
                        item.userData?.playbackPositionTicks ?? 0 > 0 ? L10n.resume : L10n.play,
                        icon: "play",
                        action: {
                            // TODO: Handle folders/shows/series
                            mainRouter.route(
                                to: \.videoPlayer,
                                OnlineVideoPlayerManager(
                                    item: item,
                                    mediaSource: item.mediaSources!.first!
                                )
                            )
                        }
                    )
                    /// Play From Beginning
                    /* if (item.userData?.playbackPositionTicks ?? 0) > 0 {
                         ContextMenuButton(
                             L10n.playFromBeginning,
                             icon: "repeat",
                             action: {}
                         )
                     }
                     /// Shuffle Season/Folder
                     if item.isFolder == true {
                         ContextMenuButton(
                             "Shuffle",
                             icon: "shuffle",
                             action: {}
                         )
                     } */
                }
            }
        }

        // MARK: - Action Buttons

        @ViewBuilder
        private var actionButtons: some View {
            Section(L10n.options) {
                /// Toggle Played
                if (item.userData?.playbackPositionTicks ?? 0) > 0 || item.userData?.isPlayed ?? false == false {
                    ContextMenuButton(
                        L10n.played,
                        icon: "checkmark.circle",
                        action: {
                            itemViewModel.send(.toggleIsPlayed(setPlayed: true))
                        }
                    )
                }
                /// Mark as Unplayed
                if (item.userData?.playbackPositionTicks ?? 0) > 0 || item.userData?.isPlayed ?? false {
                    ContextMenuButton(
                        L10n.unplayed,
                        icon: "minus.circle",
                        role: .destructive,
                        action: {
                            itemViewModel.send(.toggleIsPlayed(setPlayed: false))
                        }
                    )
                }
                /// Toggle Favorite
                ContextMenuButton(
                    item.userData?.isFavorite == false ? "Favorite" : "Unfavorite",
                    icon: item.userData?.isFavorite == false ? "heart" : "heart.slash.fill",
                    action: {
                        itemViewModel.send(.toggleIsFavorite())
                    }
                )
                /// Add to Playlist
                /* ContextMenuButton(
                     "Add to Playlist",
                     icon: "text.badge.plus",
                     action: {}
                 )
                 /// Download
                  ContextMenuButton(
                     "Download",
                     icon: "square.and.arrow.down",
                     action: {}
                 ) */
            }
        }

        // MARK: - Management Buttons

        @ViewBuilder
        private var managementButtons: some View {
            Section(L10n.management) {
                /// Refresh Metadata
                if userSession?.user.permissions.items.canEditMetadata ?? false {
                    ContextMenuButton(
                        L10n.refreshMetadata,
                        icon: "arrow.clockwise",
                        action: {
                            refreshViewModel.send(
                                .refreshMetadata(
                                    metadataRefreshMode: .default,
                                    imageRefreshMode: .default,
                                    replaceMetadata: false,
                                    replaceImages: false
                                )
                            )
                        }
                    )
                }
                /// Delete Item
                if userSession?.user.permissions.items.canDelete ?? false && item.canDelete ?? false {
                    ContextMenuButton(
                        L10n.delete,
                        icon: "trash",
                        role: .destructive,
                        action: {
                            if item.canDelete ?? false {
                                deleteViewModel.send(.delete)
                            }
                        }
                    )
                }
            }
        }
    }
}
