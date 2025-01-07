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

        let imageURL: URL?
        let imageIndex: Int?
        let imageLanguage: String?
        let imageWidth: Int?
        let imageHeight: Int?
        let provider: String?
        let rating: Double?
        let ratingType: RatingType?
        let ratingVotes: Int?

        // MARK: - Initializer

        init(
            imageURL: URL? = nil,
            imageIndex: Int? = nil,
            imageLanguage: String? = nil,
            imageWidth: Int? = nil,
            imageHeight: Int? = nil,
            provider: String? = nil,
            rating: Double? = nil,
            ratingType: RatingType? = nil,
            ratingVotes: Int? = nil
        ) {
            self.imageURL = imageURL
            self.imageIndex = imageIndex
            self.imageLanguage = imageLanguage
            self.imageWidth = imageWidth
            self.imageHeight = imageHeight
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

                if let imageLanguage {
                    TextPairView(leading: L10n.language, trailing: imageLanguage)
                }

                if let imageWidth, let imageHeight {
                    TextPairView(
                        leading: L10n.dimensions,
                        trailing: "\(imageWidth) x \(imageHeight)"
                    )
                }

                if let imageIndex {
                    TextPairView(leading: L10n.index, trailing: imageIndex.description)
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

            if let imageURL = imageURL {
                Section {
                    Button {
                        UIApplication.shared.open(imageURL)
                    } label: {
                        HStack {
                            Text(L10n.imageSource)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundColor(.primary)

                            Image(systemName: "arrow.up.forward")
                                .font(.body.weight(.regular))
                                .foregroundColor(.secondary)
                        }
                        .foregroundStyle(.primary, .secondary)
                    }
                }
            }
        }
    }
}
