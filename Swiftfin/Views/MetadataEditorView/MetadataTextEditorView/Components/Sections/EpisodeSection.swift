//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import JellyfinAPI
import SwiftUI

extension MetadataTextEditorView {
    struct EpisodeSection: View {
        @Binding
        var item: BaseItemDto

        var body: some View {
            Section("Locked fields") {
                Toggle("Lock all fields", isOn: Binding(get: {
                    item.lockData ?? false
                }, set: {
                    item.lockData = $0
                }))

                if item.lockData != true {
                    ForEach(MetadataField.allCases, id: \.self) { field in
                        Toggle(field.rawValue, isOn: Binding(
                            get: { item.lockedFields?.contains(field) ?? false },
                            set: { isSelected in
                                if isSelected {
                                    item.lockedFields?.append(field)
                                } else {
                                    item.lockedFields?.removeAll { $0 == field }
                                }
                            }
                        ))
                    }
                }
            }
        }
    }
}
