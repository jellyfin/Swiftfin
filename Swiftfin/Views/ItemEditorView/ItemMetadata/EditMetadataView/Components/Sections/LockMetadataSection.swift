//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import JellyfinAPI
import SwiftUI

extension EditMetadataView {

    struct LockMetadataSection: View {

        @Binding
        var item: BaseItemDto

        // TODO: Animation when lockAllFields is selected
        var body: some View {
            Section(L10n.lockedFields) {
                Toggle(
                    L10n.lockAllFields,
                    isOn: $item.lockData.coalesce(false)
                )
            }

            if item.lockData != true {
                Section {
                    ForEach(MetadataField.allCases, id: \.self) { field in
                        Toggle(
                            field.displayTitle,
                            isOn: $item.lockedFields
                                .coalesce([])
                                .contains(field)
                        )
                    }
                }
            }
        }
    }
}
