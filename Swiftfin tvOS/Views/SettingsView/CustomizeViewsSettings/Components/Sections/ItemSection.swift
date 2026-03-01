//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import SwiftUI

extension CustomizeViewsSettings {

    struct ItemSection: View {

        @Injected(\.currentUserSession)
        private var userSession

        @Router
        private var router

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
                    router.route(to: .itemViewAttributes(selection: $itemViewAttributes))
                }

                ListRowMenu(L10n.enabledTrailers, selection: $enabledTrailers)

                /// Enable Refreshing & Deleting Collections
                if userSession?.user.permissions.items.canManageCollections == true {
                    Toggle(L10n.editCollections, isOn: $enableCollectionManagement)
                }
                /// Enable Refreshing Items from All Visible LIbraries
                if userSession?.user.permissions.items.canEditMetadata == true {
                    Toggle(L10n.editMedia, isOn: $enableItemEditing)
                }
                /// Enable Deleting Items from Approved Libraries
                if userSession?.user.permissions.items.canDelete == true {
                    Toggle(L10n.deleteMedia, isOn: $enableItemDeletion)
                }
            }
        }
    }
}
