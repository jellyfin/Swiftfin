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

                Section("Taglines") {
                    EditableListView(
                        title: "Tagline",
                        items: Binding(
                            get: { item.taglines ?? [] },
                            set: { item.taglines = $0 }
                        )
                    )
                }
            }

            Section("Overview") {
                TextEditor(text: Binding(get: {
                    item.overview ?? ""
                }, set: {
                    item.overview = $0
                }))
                .frame(minHeight: 100)
            }
        }
    }
}
