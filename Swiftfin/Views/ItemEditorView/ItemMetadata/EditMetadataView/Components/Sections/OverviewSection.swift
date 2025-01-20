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

    struct OverviewSection: View {

        // MARK: - Metadata Variables

        @Binding
        var item: BaseItemDto

        let itemType: BaseItemKind

        // MARK: - Show Tagline

        private var showTaglines: Bool {
            [
                BaseItemKind.movie,
                .series,
                .audioBook,
                .book,
                .audio,
            ].contains(itemType)
        }

        // MARK: - Body

        var body: some View {
            if showTaglines {
                // There doesn't seem to be a usage anywhere of more than 1 tagline?
                Section(L10n.taglines) {
                    TextField(
                        L10n.tagline,
                        value: $item.taglines
                            .map(
                                getter: { $0 == nil ? "" : $0!.first },
                                setter: { $0 == nil ? [] : [$0!] }
                            ),
                        format: .nilIfEmptyString
                    )
                }
            }

            Section(L10n.overview) {
                TextEditor(text: $item.overview.coalesce(""))
                    .onAppear {
                        // Workaround for iOS 17 and earlier bug
                        // where the row height won't be set properly
                        item.overview = item.overview
                    }
            }
        }
    }
}
