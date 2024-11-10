//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension CustomizeViewsSettings {

    struct ItemSection: View {

        @StoredValue(.User.enableItemEditor)
        private var enableItemEditor
        @StoredValue(.User.enableItemDeletion)
        private var enableItemDeletion

        var body: some View {
            Section(L10n.items) {

                Toggle(L10n.allowItemEditing, isOn: $enableItemEditor)

                Toggle(L10n.allowItemDeletion, isOn: $enableItemDeletion)
            }
        }
    }
}
