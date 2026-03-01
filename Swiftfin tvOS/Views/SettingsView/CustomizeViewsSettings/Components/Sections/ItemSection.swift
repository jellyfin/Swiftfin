//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import JellyfinAPI
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

        private var userPolicy: UserPolicy? {
            userSession?.user.data.policy
        }

        private var isAdminstrator: Bool {
            userPolicy?.isAdministrator == true
        }

        var body: some View {
            Section(L10n.items) {

                ChevronButton(L10n.mediaAttributes) {
                    router.route(to: .itemViewAttributes(selection: $itemViewAttributes))
                }

                ListRowMenu(L10n.enabledTrailers, selection: $enabledTrailers)

                /// Enable Refreshing Items from All Visible LIbraries
                if isAdminstrator {
                    Toggle(L10n.editMedia, isOn: $enableItemEditing)
                }
                /// Enable Refreshing & Deleting Collections
                if isAdminstrator || userPolicy?.enableCollectionManagement == true {
                    Toggle(L10n.editCollections, isOn: $enableCollectionManagement)
                }
                /// Enable Deleting Items from Approved Libraries
                if isAdminstrator || userPolicy?.enableContentDeletion == true {
                    Toggle(L10n.deleteMedia, isOn: $enableItemDeletion)
                }
            }
        }
    }
}
