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
    struct ReviewsSection: View {
        @Binding
        var item: BaseItemDto

        var body: some View {
            Section("Reviews") {
                ChevronAlertButton(
                    "Critics",
                    subtitle: item.criticRating.map { "\($0)" } ?? .emptyDash,
                    description: "Critics rating out of 10"
                ) {
                    TextField(
                        "Rating",
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

                ChevronAlertButton(
                    "Community",
                    subtitle: item.communityRating.map { "\($0)" } ?? .emptyDash,
                    description: "Community rating out of 10"
                ) {
                    TextField(
                        "Rating",
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
