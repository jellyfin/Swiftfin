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

    struct SyncPlaySection: View {

        @Environment(\.isEditing)
        var isEditing

        @Binding
        var policy: UserPolicy

        var body: some View {
            Section("SyncPlay access") {
                Picker(
                    "SyncPlay policy",
                    selection: Binding(
                        get: { policy.syncPlayAccess ?? SyncPlayUserAccessType.none },
                        set: { policy.syncPlayAccess = $0 }
                    )
                ) {
                    ForEach(SyncPlayUserAccessType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .disabled(!isEditing)
            }
        }
    }
}
