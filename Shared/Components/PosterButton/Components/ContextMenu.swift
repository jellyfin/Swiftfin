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

    struct ContextMenu: View {

        // MARK: - Current User Session

        @Injected(\.currentUserSession)
        private var userSession

        #if os(tvOS)
        @EnvironmentObject
        private var router: ItemCoordinator.Router
        #else
        @EnvironmentObject
        private var router: MainCoordinator.Router
        #endif

        // MARK: - PosterButton ContextMenu Variables

        private let item: BaseItemDto

        // MARK: - State Object Variables

        @StateObject
        private var itemViewModel: ItemViewModel
        @StateObject
        private var refreshViewModel: RefreshMetadataViewModel
        @StateObject
        private var deleteViewModel: DeleteItemViewModel

        // MARK: - Playback Resumables

        private var playbackResumable: Bool {
            item.userData?.playbackPositionTicks ?? 0 > 0
        }

        // MARK: - Playback Title

        private var playbackSubtitle: String? {
            if let series = itemViewModel as? SeriesItemViewModel {
                return series.playButtonItem?.seasonEpisodeLabel
            } else if playbackResumable {
                return itemViewModel.playButtonItem?.playButtonLabel
            } else {
                return nil
            }
        }

        // MARK: - Initializer

        init(_ item: BaseItemDto) {
            self.item = item

            switch item.type {
            case .boxSet:
                self._itemViewModel = .init(wrappedValue: CollectionItemViewModel(item: item))
            case .episode:
                self._itemViewModel = .init(wrappedValue: EpisodeItemViewModel(item: item))
            case .movie:
                self._itemViewModel = .init(wrappedValue: MovieItemViewModel(item: item))
            case .series:
                self._itemViewModel = .init(wrappedValue: SeriesItemViewModel(item: item))
            default:
                self._itemViewModel = .init(wrappedValue: ItemViewModel(item: item))
            }

            self._refreshViewModel = .init(wrappedValue: .init(item: item))
            self._deleteViewModel = .init(wrappedValue: .init(item: item))
        }

        // MARK: - Body

        var body: some View {
            Group {
                playbackButtons
                actionButtons
                managementButtons
            }
            .onFirstAppear {
                itemViewModel.send(.refresh)
            }
        }

        // MARK: - Playback Buttons

        @ViewBuilder
        private var playbackButtons: some View {
            Section(L10n.media) {
                /// Play / Resume
                if let playButtonItem = itemViewModel.playButtonItem {
                    ContextMenuButton(
                        playbackResumable ? L10n.resume : L10n.play,
                        subtitle: playbackSubtitle,
                        icon: "play",
                        action: {
                            router.route(
                                to: \.videoPlayer,
                                OnlineVideoPlayerManager(
                                    item: playButtonItem,
                                    mediaSource: playButtonItem.mediaSources!.first!
                                )
                            )
                        }
                    )
                }
                /// Play From Beginning
                /* if playbackResumable {
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

        // MARK: - Action Buttons

        @ViewBuilder
        private var actionButtons: some View {
            Section(L10n.options) {
                /// Mark as Played
                if playbackResumable || item.userData?.isPlayed == false {
                    ContextMenuButton(
                        L10n.played,
                        icon: "checkmark.circle",
                        action: {
                            itemViewModel.send(.toggleIsPlayed(setPlayed: true))
                        }
                    )
                }
                /// Mark as Unplayed
                if playbackResumable || item.userData?.isPlayed ?? false {
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
                if (item.type == .boxSet && userSession?.user.permissions.items.canManageCollections ?? false) ||
                    userSession?.user.permissions.items.canEditMetadata ?? false
                {
                    #if os(iOS)
                    /// Edit Metadata
                    ContextMenuButton(
                        L10n.edit,
                        icon: "gearshape",
                        action: {
                            router.route(to: \.itemEditor, itemViewModel)
                        }
                    )
                    #endif
                    /// Refresh Metadata
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
                if (item.type == .boxSet && userSession?.user.permissions.items.canManageCollections ?? false) ||
                    userSession?.user.permissions.items.canDelete ?? false &&
                    item.canDelete ?? false
                {
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
