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

    struct TitleSection: View {

        @Binding
        var item: BaseItemDto

        var body: some View {
            Section(L10n.title) {
                TextField(
                    L10n.title,
                    value: $item.name,
                    format: .nilIfEmptyString
                )
            }

            Section(L10n.originalTitle) {
                TextField(
                    L10n.originalTitle,
                    value: $item.originalTitle,
                    format: .nilIfEmptyString
                )
            }

            Section(L10n.sortTitle) {
                TextField(
                    L10n.sortTitle,
                    value: $item.forcedSortName,
                    format: .nilIfEmptyString
                )
            }
        }
    }
}
