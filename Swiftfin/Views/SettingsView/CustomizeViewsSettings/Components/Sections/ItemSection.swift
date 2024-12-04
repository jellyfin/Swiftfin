//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import SwiftUI

extension CustomizeViewsSettings {

    struct ItemSection: View {

        @Injected(\.currentUserSession)
        private var userSession

        @StoredValue(.User.enableItemEditor)
        private var enableItemEditor
        @StoredValue(.User.enableItemDeletion)
        private var enableItemDeletion

        var body: some View {
            Section(L10n.items) {
                /* if userSession?.user.hasItemDownloadPermissions ?? false {
                     Toggle(L10n.allowItemDeletion, isOn: $enableItemDeletion)
                 } */

                if userSession?.user.hasMetadataEditingPermissions ?? false {
                    Toggle(L10n.allowItemEditing, isOn: $enableItemEditor)
                }

                /* if userSession?.user.hasCollectionManagementPermissions ?? false {
                     Toggle(L10n.allowItemDeletion, isOn: $enableItemDeletion)
                 }*/

                if userSession?.user.hasItemDeletionPermissions ?? false {
                    Toggle(L10n.allowItemDeletion, isOn: $enableItemDeletion)
                }

                /* if userSession?.user.hasLyricManagementPermissions ?? false {
                     Toggle(L10n.allowItemDeletion, isOn: $enableItemDeletion)
                 }

                 if userSession?.user.hasSubtitleManagementPermissions ?? false {
                     Toggle(L10n.allowItemDeletion, isOn: $enableItemDeletion)
                 }*/
            }
        }
    }
}
