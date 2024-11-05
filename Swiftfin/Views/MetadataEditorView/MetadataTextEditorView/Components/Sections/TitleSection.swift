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
    struct TitleSection: View {
        @Binding
        var item: BaseItemDto
        let itemType: BaseItemKind

        var body: some View {
            Section(L10n.filePath) {
                Text(item.path ?? L10n.unknown)
            }

            Section(L10n.title) {
                TextField(L10n.title, text: Binding(get: {
                    item.name ?? ""
                }, set: {
                    item.name = $0
                }))
            }

            Section(L10n.originalTitle) {
                TextField(L10n.originalTitle, text: Binding(get: {
                    item.originalTitle ?? ""
                }, set: {
                    item.originalTitle = $0
                }))
            }

            Section(L10n.sortTitle) {
                TextField(L10n.sortTitle, text: Binding(get: {
                    item.forcedSortName ?? ""
                }, set: {
                    item.forcedSortName = $0
                }))
            }
        }
    }
}
