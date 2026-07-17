//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import FactoryKit
import SwiftUI

extension CustomizeViewsSettings {

    #if os(tvOS)
    typealias PlatformPicker = ListRowMenu
    #else
    typealias PlatformPicker = Picker
    #endif

    struct ItemSection: View {

        @Injected(\.currentUserSession)
        private var userSession

        @Router
        private var router

        @Default(.Customization.itemViewType)
        private var itemViewType

        @StoredValue(.User.enabledTrailers)
        private var enabledTrailers

        @StoredValue(.User.enableItemEditing)
        private var enableItemEditing
        @StoredValue(.User.enableItemDeletion)
        private var enableItemDeletion
        @StoredValue(.User.enableCollectionManagement)
        private var enableCollectionManagement

        @Default(.Customization.shouldShowMissingSeasons)
        private var shouldShowMissingSeasons
        @Default(.Customization.shouldShowMissingEpisodes)
        private var shouldShowMissingEpisodes

        private var presentMangementSection: Bool {
            userSession?.user.data.policy?.isAdministrator == true ||
                userSession?.user.data.policy?.enableCollectionManagement == true ||
                userSession?.user.data.policy?.enableContentDeletion == true ||
                userSession?.user.data.policy?.enableContentDeletionFromFolders?.isNotEmpty == true
        }

        var body: some View {
            Form(systemImage: "gear") {
                Section {
                    PlatformPicker(L10n.style, selection: $itemViewType)
                } header: {
                    Text(L10n.itemView)
                }

                PlatformPicker(L10n.enabledTrailers, selection: $enabledTrailers)

                if presentMangementSection {
                    Section(L10n.management) {

                        if userSession?.user.data.policy?.isAdministrator == true ||
                            userSession?.user.data.policy?.enableCollectionManagement == true
                        {
                            Toggle(L10n.editCollections, isOn: $enableCollectionManagement)
                        }

                        if userSession?.user.data.policy?.isAdministrator == true {
                            Toggle(L10n.editMedia, isOn: $enableItemEditing)
                        }

                        if userSession?.user.data.policy?.isAdministrator == true ||
                            userSession?.user.data.policy?.enableContentDeletion == true ||
                            userSession?.user.data.policy?.enableContentDeletionFromFolders?.isNotEmpty == true
                        {
                            Toggle(L10n.deleteMedia, isOn: $enableItemDeletion)
                        }
                    }
                }

                Section {
                    Toggle(L10n.showMissingSeasons, isOn: $shouldShowMissingSeasons)
                    Toggle(L10n.showMissingEpisodes, isOn: $shouldShowMissingEpisodes)
                } header: {
                    Text(L10n.missing)
                }
            }
            .navigationTitle(L10n.items)
        }
    }
}
