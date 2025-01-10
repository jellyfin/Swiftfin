//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import SwiftUI

extension CustomizeViewsSettings {

    struct ItemSection: View {

        @Injected(\.currentUserSession)
        private var userSession

        @Default(.Customization.itemViewType)
        private var itemViewType
        @Default(.Customization.CinematicItemViewType.usePrimaryImage)
        private var cinematicItemViewTypeUsePrimaryImage

        @Default(.Customization.Episodes.useSeriesLandscapeBackdrop)
        private var useSeriesLandscapeBackdrop

        @Default(.Customization.shouldShowMissingSeasons)
        private var shouldShowMissingSeasons
        @Default(.Customization.shouldShowMissingEpisodes)
        private var shouldShowMissingEpisodes

        @StoredValue(.User.enableItemEditing)
        private var enableItemEditing
        @StoredValue(.User.enableItemDeletion)
        private var enableItemDeletion
        @StoredValue(.User.enableCollectionManagement)
        private var enableCollectionManagement

        var body: some View {

            Section {
                if UIDevice.isPhone {

                    // MARK: iPhone Item View Type

                    CaseIterablePicker(
                        L10n.items,
                        selection: $itemViewType
                    )

                    if itemViewType == .cinematic {

                        // MARK: iPhone Item View Type - Cinematic Primary Poster

                        Toggle(
                            L10n.usePrimaryImage.localizedCapitalized,
                            isOn: $cinematicItemViewTypeUsePrimaryImage
                        )
                    }
                }
            } header: {
                Text(L10n.items)
            } footer: {
                if itemViewType == .cinematic {
                    Text(L10n.usePrimaryImageDescription)
                }
            }

            Section {

                // MARK: Use Series Images for Episodes

                Toggle(
                    L10n.seriesBackdrop.localizedCapitalized,
                    isOn: $useSeriesLandscapeBackdrop
                )
            } footer: {
                Text(L10n.seriesBackdropDescription)
            }

            Section {

                // MARK: Show Missing - Seasons

                Toggle(
                    L10n.showMissingSeasons.localizedCapitalized,
                    isOn: $shouldShowMissingSeasons
                )

                // MARK: Show Missing - Episodes

                Toggle(
                    L10n.showMissingEpisodes.localizedCapitalized,
                    isOn: $shouldShowMissingEpisodes
                )
            } header: {
                Text(L10n.missingItems)
            } footer: {
                Text(L10n.missingItemsDisplayed)
            }

            if userSession?.user.permissions.items.canEditMetadata ?? false
                || userSession?.user.permissions.items.canDelete ?? false
                || userSession?.user.permissions.items.canDownload ?? false
                || userSession?.user.permissions.items.canManageCollections ?? false
                || userSession?.user.permissions.items.canManageLyrics ?? false
                || userSession?.user.permissions.items.canManageSubtitles ?? false
            {
                Section(L10n.management) {

                    // MARK: Item - Metadata Editing

                    if userSession?.user.permissions.items.canEditMetadata ?? false {
                        Toggle(
                            L10n.allowItemEditing.localizedCapitalized,
                            isOn: $enableItemEditing
                        )
                    }

                    // MARK: Item - Lyrics Editing

                    /* if userSession?.user.permissions.items.canManageLyrics ?? false {
                        Toggle(
                            L10n.allowLyricsManagement.localizedCapitalized,
                            isOn: $enableLyricsManagement
                        )
                     } */

                    // MARK: Item - Subtitle Editing

                    /* if userSession?.user.items.canManageSubtitles ?? false {
                        Toggle(
                            L10n.allowSubtitleManagement.localizedCapitalized,
                            isOn: $enableSubtitleManagement
                        )
                     } */

                    // MARK: Item - Deletion

                    if userSession?.user.permissions.items.canDelete ?? false {
                        Toggle(
                            L10n.allowItemDeletion.localizedCapitalized,
                            isOn: $enableItemDeletion
                        )
                    }

                    // MARK: Item - Downloading

                    /* if userSession?.user.permissions.items.canDownload ?? false {
                        Toggle(
                            L10n.allowItemDownloading.localizedCapitalized,
                            isOn: $enableItemDownloads
                        )
                     } */

                    // MARK: Collection - Metadata Editing & Deletion

                    if userSession?.user.permissions.items.canManageCollections ?? false {
                        Toggle(
                            L10n.allowCollectionManagement.localizedCapitalized,
                            isOn: $enableCollectionManagement
                        )
                    }
                }
            }
        }
    }
}
