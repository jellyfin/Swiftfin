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

    struct ReviewsSection: View {

        @Binding
        var item: BaseItemDto

        // MARK: - Body

        var body: some View {
            Section(L10n.reviews) {

                // MARK: - Critics Rating

                ChevronAlertButton(
                    L10n.critics,
                    subtitle: item.criticRating.map { "\($0)" } ?? .emptyDash,
                    description: L10n.ratingDescription(L10n.critics)
                ) {
                    TextField(
                        L10n.rating,
                        value: $item.criticRating,
                        format: .number.precision(.fractionLength(1))
                    )
                    .keyboardType(.decimalPad)
                    .onChange(of: item.criticRating) { _ in
                        if let rating = item.criticRating {
                            item.criticRating = min(max(rating, 0), 10)
                        }
                    }
                }

                // MARK: - Community Rating

                ChevronAlertButton(
                    L10n.community,
                    subtitle: item.communityRating.map { "\($0)" } ?? .emptyDash,
                    description: L10n.ratingDescription(L10n.community)
                ) {
                    TextField(
                        L10n.rating,
                        value: $item.communityRating,
                        format: .number.precision(.fractionLength(1))
                    )
                    .keyboardType(.decimalPad)
                    .onChange(of: item.communityRating) { _ in
                        if let rating = item.communityRating {
                            item.communityRating = min(max(rating, 0), 10)
                        }
                    }
                }
            }
        }
    }
}
