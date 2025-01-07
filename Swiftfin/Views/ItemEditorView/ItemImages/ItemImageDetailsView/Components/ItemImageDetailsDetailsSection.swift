//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ItemImageDetailsView {

    struct DetailsSection: View {

        // MARK: - Image Details Variables

        let index: Int?
        let language: String?
        let width: Int?
        let height: Int?
        let provider: String?

        // MARK: - Image Ratings Variables

        let rating: Double?
        let ratingType: RatingType?
        let ratingVotes: Int?

        // MARK: - Image Source Variable

        let url: URL?

        // MARK: - Initializer

        init(
            url: URL? = nil,
            index: Int? = nil,
            language: String? = nil,
            width: Int? = nil,
            height: Int? = nil,
            provider: String? = nil,
            rating: Double? = nil,
            ratingType: RatingType? = nil,
            ratingVotes: Int? = nil
        ) {
            self.url = url
            self.index = index
            self.language = language
            self.width = width
            self.height = height
            self.provider = provider
            self.rating = rating
            self.ratingType = ratingType
            self.ratingVotes = ratingVotes
        }

        // MARK: - Body

        @ViewBuilder
        var body: some View {
            Section(L10n.details) {
                if let provider {
                    TextPairView(leading: L10n.provider, trailing: provider)
                }

                if let language {
                    TextPairView(leading: L10n.language, trailing: language)
                }

                if let width, let height {
                    TextPairView(
                        leading: L10n.dimensions,
                        trailing: "\(width) x \(height)"
                    )
                }

                if let index {
                    TextPairView(leading: L10n.index, trailing: index.description)
                }
            }

            if let rating {
                Section(L10n.ratings) {
                    TextPairView(leading: L10n.rating, trailing: rating.formatted(.number.precision(.fractionLength(2))))

                    if let ratingType {
                        TextPairView(leading: L10n.type, trailing: ratingType.displayTitle)
                    }

                    if let ratingVotes {
                        TextPairView(leading: L10n.votes, trailing: ratingVotes.description)
                    }
                }
            }

            if let url {
                Section {
                    ChevronButton(
                        L10n.imageSource,
                        external: true
                    )
                    .onSelect {
                        UIApplication.shared.open(url)
                    }
                }
            }
        }
    }
}
