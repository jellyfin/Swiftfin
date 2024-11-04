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
    struct ParentalRatingSection: View {
        @Binding
        var item: BaseItemDto
        @ObservedObject
        private var viewModel = ParentalRatingsViewModel()

        @State
        private var officialRatings: [ParentalRating] = []
        @State
        private var customRatings: [ParentalRating] = []

        // MARK: - Body

        var body: some View {
            Section("Parental Rating") {

                // MARK: Official Rating Picker

                Picker("Official Rating", selection: Binding<ParentalRating?>(
                    get: {
                        if let ratingName = item.officialRating {
                            return officialRatings.first { $0.name == ratingName }
                        } else {
                            return nil
                        }
                    },
                    set: { newValue in
                        item.officialRating = newValue?.name
                    }
                )) {
                    Text(L10n.none).tag(nil as ParentalRating?)
                    ForEach(officialRatings) { rating in
                        Text(rating.name ?? "").tag(rating as ParentalRating?)
                    }
                }
                .onAppear {
                    updateOfficialRatings()
                }
                .onChange(of: viewModel.parentalRatings) { _ in
                    updateOfficialRatings()
                }

                // MARK: Custom Rating Picker

                Picker("Custom Rating", selection: Binding<ParentalRating?>(
                    get: {
                        if let ratingName = item.customRating {
                            return customRatings.first { $0.name == ratingName }
                        } else {
                            return nil
                        }
                    },
                    set: { newValue in
                        item.customRating = newValue?.name
                    }
                )) {
                    Text(L10n.none).tag(nil as ParentalRating?)
                    ForEach(customRatings) { rating in
                        Text(rating.name ?? "").tag(rating as ParentalRating?)
                    }
                }
                .onAppear {
                    updateCustomRatings()
                }
                .onChange(of: viewModel.parentalRatings) { _ in
                    updateCustomRatings()
                }
            }
            .onFirstAppear {
                viewModel.send(.refresh)
            }
        }

        // MARK: - Update Official Rating

        private func updateOfficialRatings() {
            officialRatings = viewModel.parentalRatings
            if let currentRatingName = item.officialRating,
               !officialRatings.contains(where: { $0.name == currentRatingName })
            {
                officialRatings.append(ParentalRating(name: currentRatingName))
            }
        }

        // MARK: - Update Custom Rating

        private func updateCustomRatings() {
            customRatings = viewModel.parentalRatings
            if let currentRatingName = item.customRating,
               !customRatings.contains(where: { $0.name == currentRatingName })
            {
                customRatings.append(ParentalRating(name: currentRatingName))
            }
        }
    }
}
