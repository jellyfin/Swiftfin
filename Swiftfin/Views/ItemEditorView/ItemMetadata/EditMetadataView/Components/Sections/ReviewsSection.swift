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

                ChevronButton(
                    L10n.critics,
                    subtitle: item.criticRating
                        .map { FloatingPointFormatStyle<Float>.number
                            .precision(.fractionLength(0 ... 2)).format($0)
                        } ?? .emptyDash,
                    description: L10n.criticRatingDescription
                ) {
                    TextField(
                        L10n.rating,
                        value: $item.criticRating,
                        format: .number
                    )
                    .keyboardType(.decimalPad)
                    .onChange(of: item.criticRating) { _ in
                        if let rating = item.criticRating {
                            item.criticRating = min(max(rating, 0), 100)
                        }
                    }
                }

                // MARK: - Community Rating

                ChevronButton(
                    L10n.community,
                    subtitle: item.communityRating
                        .map { FloatingPointFormatStyle<Float>.number
                            .precision(.fractionLength(0 ... 2)).format($0)
                        } ?? .emptyDash,
                    description: L10n.communityRatingDescription
                ) {
                    TextField(
                        L10n.rating,
                        value: $item.communityRating,
                        format: .number
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
