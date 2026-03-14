//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ItemView.AboutView {

    struct RatingsCard: View {

        let item: BaseItemDto

        var body: some View {
            Card(title: L10n.ratings)
                .content {
                    HStack(alignment: .bottom) {
                        if let criticRating = item.criticRating {
                            VStack {
                                Group {
                                    if criticRating >= 60 {
                                        Image(.tomatoFresh)
                                    } else {
                                        Image(.tomatoRotten)
                                    }
                                }
                                .symbolRenderingMode(.multicolor)
                                .foregroundStyle(.green, .red)
                                .font(.largeTitle)

                                Text("\(criticRating, specifier: "%.0f")")
                                    .font(.title3)
                            }
                        }

                        if let communityRating = item.communityRating {
                            VStack {
                                Image(systemName: "star.fill")
                                    .symbolRenderingMode(.multicolor)
                                    .foregroundStyle(.yellow)
                                    .font(.largeTitle)

                                Text("\(communityRating, specifier: "%.1f")")
                                    .font(.title3)
                            }
                        }
                    }
                }
        }
    }
}
