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

        @EnvironmentObject
        private var router: SettingsCoordinator.Router

        @StoredValue(.User.itemViewAttributes)
        private var itemViewAttributes
        @StoredValue(.User.enabledTrailers)
        private var enabledTrailers

        @StoredValue(.User.enableItemEditing)
        private var enableItemEditing
        @StoredValue(.User.enableItemDeletion)
        private var enableItemDeletion
        @StoredValue(.User.enableCollectionManagement)
        private var enableCollectionManagement

        var body: some View {
            Section(L10n.items) {

                ChevronButton(L10n.mediaAttributes) {
                    router.route(to: \.itemViewAttributes, $itemViewAttributes)
                }

                CaseIterablePicker(
                    L10n.enabledTrailers,
                    selection: $enabledTrailers
                )

                /// Enabled Collection Management for collection managers
                if userSession?.user.permissions.items.canManageCollections == true {
                    Toggle(L10n.editCollections, isOn: $enableCollectionManagement)
                }
                /// Enabled Media Management when there are media elements that can be managed
                if userSession?.user.permissions.items.canEditMetadata == true ||
                    userSession?.user.permissions.items.canManageLyrics == true ||
                    userSession?.user.permissions.items.canManageSubtitles == true
                {
                    Toggle(L10n.editMedia, isOn: $enableItemEditing)
                }
                /// Enabled Media Deletion for valid deletion users
                if userSession?.user.permissions.items.canDelete == true {
                    Toggle(L10n.deleteMedia, isOn: $enableItemDeletion)
                }
            }
        }
    }
}
