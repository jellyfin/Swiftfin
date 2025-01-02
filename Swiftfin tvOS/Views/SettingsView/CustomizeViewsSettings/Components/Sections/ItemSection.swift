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

        @StoredValue(.User.enableItemEditing)
        private var enableItemEditing
        @StoredValue(.User.enableItemDeletion)
        private var enableItemDeletion
        @StoredValue(.User.enableCollectionManagement)
        private var enableCollectionManagement

        var body: some View {
            if userSession?.user.permissions.items.canEditMetadata ?? false ||
                userSession?.user.permissions.items.canDelete ?? false ||
                userSession?.user.permissions.items.canManageCollections ?? false
            {

                Section(L10n.items) {
                    /// Enable Refreshing Items from All Visible LIbraries
                    if userSession?.user.permissions.items.canEditMetadata ?? false {
                        Toggle(L10n.allowItemEditing, isOn: $enableItemEditing)
                    }
                    /// Enable Deleting Items from Approved Libraries
                    if userSession?.user.permissions.items.canDelete ?? false {
                        Toggle(L10n.allowItemDeletion, isOn: $enableItemDeletion)
                    }
                    /// Enable Refreshing & Deleting Collections
                    if userSession?.user.permissions.items.canManageCollections ?? false {
                        Toggle(L10n.allowCollectionManagement, isOn: $enableCollectionManagement)
                    }
                }
            }
        }
    }
}
