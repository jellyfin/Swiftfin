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
    struct AssociationsSection: View {
        @Binding
        var item: BaseItemDto

        var body: some View {
            Section(L10n.genres) {
                EditableListView(
                    title: "Genre",
                    items: Binding(
                        get: { item.genres ?? [] },
                        set: { item.genres = $0 }
                    )
                )
            }

            Section(L10n.people) {
                BasePersonEditorView(
                    title: "Person",
                    items: Binding(
                        get: { item.people ?? [] },
                        set: { item.people = $0 }
                    )
                )
            }

            Section(L10n.tags) {
                EditableListView(
                    title: "Tag",
                    items: Binding(
                        get: { item.tags ?? [] },
                        set: { item.tags = $0 }
                    )
                )
            }
        }
    }
}
