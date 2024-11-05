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

extension EditMetadataView {
    struct OverviewSection: View {
        @Binding
        var item: BaseItemDto

        let itemType: BaseItemKind

        var body: some View {
            if itemType == .movie ||
                itemType == .series ||
                itemType == .audioBook ||
                itemType == .book ||
                itemType == .audio
            {
                // There doesn't seem to be a usage anywhere of more than 1 tagline?
                Section(L10n.taglines) {
                    TextField(L10n.tagline, text: Binding(
                        get: { item.taglines?.first ?? "" },
                        set: { newValue in
                            item.taglines = newValue.isEmpty ? nil : [newValue]
                        }
                    ))
                }
            }

            // TODO: Size Up / Down with Text
            Section(L10n.overview) {
                TextEditor(text: Binding(
                    get: { item.overview ?? "" },
                    set: { item.overview = $0 }
                ))
                .frame(minHeight: 100, maxHeight: .infinity)
            }
        }
    }
}
