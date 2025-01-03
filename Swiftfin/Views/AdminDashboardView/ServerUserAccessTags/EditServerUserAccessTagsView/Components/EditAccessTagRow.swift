//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

extension EditServerUserAccessTagsView {

    struct EditAccessTagRow: View {

        // MARK: - Metadata Variables

        let tag: String

        // MARK: - Row Actions

        let onSelect: () -> Void
        let onDelete: () -> Void

        // MARK: - Body

        var body: some View {
            Button(action: onSelect) {
                HStack {
                    Text(tag)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ListRowCheckbox()
                }
            }
            .foregroundStyle(.primary)
            .swipeActions {
                Button(
                    L10n.delete,
                    systemImage: "trash",
                    action: onDelete
                )
                .tint(.red)
            }
        }
    }
}
