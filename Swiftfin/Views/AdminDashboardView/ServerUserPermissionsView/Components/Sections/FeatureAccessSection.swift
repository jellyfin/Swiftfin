//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ServerUserPermissionsView {

    struct FeatureAccessSection: View {

        @Environment(\.isEditing)
        var isEditing

        @Binding
        var policy: UserPolicy

        var body: some View {
            Section("Feature access") {
                Toggle("Live TV access", isOn: Binding(
                    get: { policy.enableLiveTvAccess ?? false },
                    set: { policy.enableLiveTvAccess = $0 }
                ))

                Toggle("Live TV recording management", isOn: Binding(
                    get: { policy.enableLiveTvManagement ?? false },
                    set: { policy.enableLiveTvManagement = $0 }
                ))
            }
            .disabled(!isEditing)
        }
    }
}
