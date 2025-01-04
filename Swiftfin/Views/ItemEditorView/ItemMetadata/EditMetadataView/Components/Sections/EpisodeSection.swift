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

    struct EpisodeSection: View {

        @Binding
        var item: BaseItemDto

        // MARK: - Body

        var body: some View {
            Section(L10n.season) {

                // MARK: - Season Number

                ChevronAlertButton(
                    L10n.season,
                    subtitle: item.parentIndexNumber?.description,
                    description: L10n.enterSeasonNumber
                ) {
                    TextField(
                        L10n.season,
                        value: $item.parentIndexNumber,
                        format: .number
                    )
                    .keyboardType(.numberPad)
                }

                // MARK: - Episode Number

                ChevronAlertButton(
                    L10n.episode,
                    subtitle: item.indexNumber?.description,
                    description: L10n.enterEpisodeNumber
                ) {
                    TextField(
                        L10n.episode,
                        value: $item.indexNumber,
                        format: .number
                    )
                    .keyboardType(.numberPad)
                }
            }
        }
    }
}
