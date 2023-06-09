//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ItemView.AboutView {

    struct RatingsCard: View {

        let item: BaseItemDto

        @ViewBuilder
        private var ratings: some View {
            HStack {
                if let criticRating = item.criticRating {
                    VStack {
                        Group {
                            if criticRating >= 60 {
                                Image("tomato.fresh")
                            } else {
                                Image("tomato.fresh")
                            }
                        }
                        .symbolRenderingMode(.multicolor)
                        .foregroundStyle(.green, .red)

                        Text("\(criticRating, specifier: "%.0f")")
                    }
                }

                if let communityRating = item.communityRating {
                    VStack {
                        Image(systemName: "star.fill")
                            .symbolRenderingMode(.multicolor)
                            .foregroundStyle(.yellow)

                        Text("\(communityRating, specifier: "%.1f")")
                    }
                }
            }
        }

        var body: some View {
            Card(title: "Ratings")
//                .cardContent {
//                    ratings
//                        .font(.title2)
//                }
//                .alertContent {
//                    ratings
//                        .font(.system(size: 56))
//                }
        }
    }
}
