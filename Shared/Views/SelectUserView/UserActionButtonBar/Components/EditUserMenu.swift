//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import OrderedCollections
import SwiftUI

extension SelectUserView {

    struct EditUsersMenu: View {

        @Environment(\.editMode)
        private var editMode

        private let hasUsers: Bool

        init(hasUsers: Bool) {
            self.hasUsers = hasUsers
        }

        var body: some View {
            if hasUsers {
                Toggle(
                    L10n.editUsers,
                    systemImage: "person.crop.circle",
                    isOn: Binding(
                        get: { editMode?.wrappedValue.isEditing == true },
                        set: { editMode?.wrappedValue = $0 ? .active : .inactive }
                    )
                )
            }
        }
    }
}
