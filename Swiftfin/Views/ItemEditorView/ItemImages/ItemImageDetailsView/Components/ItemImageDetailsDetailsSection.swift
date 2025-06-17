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

        private let index: Int?
        private let language: String?
        private let width: Int?
        private let height: Int?
        private let provider: String?

        // MARK: - Image Ratings Variables

        private let rating: Double?
        private let ratingVotes: Int?

        // MARK: - Image Source Variable

        private let url: URL?

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
            self.ratingVotes = ratingVotes
        }

        // MARK: - Body

        var body: some View {
            Section(L10n.details) {
                if let provider {
                    LabeledContent(L10n.provider, value: provider)
                }

                if let language {
                    LabeledContent(L10n.language, value: language)
                }

                if let width, let height {
                    LabeledContent(
                        L10n.dimensions,
                        value: "\(width) x \(height)"
                    )
                }

                if let index {
                    LabeledContent(L10n.index, value: index.description)
                }
            }

            if let rating {
                Section(L10n.ratings) {
                    LabeledContent(L10n.rating, value: rating.formatted(.number.precision(.fractionLength(2))))

                    if let ratingVotes {
                        LabeledContent(L10n.votes, value: ratingVotes, format: .number)
                    }
                }
            }

            if let url {
                Section {
                    ChevronButton(
                        L10n.imageSource,
                        external: true
                    ) {
                        UIApplication.shared.open(url)
                    }
                }
            }
        }
    }
}
