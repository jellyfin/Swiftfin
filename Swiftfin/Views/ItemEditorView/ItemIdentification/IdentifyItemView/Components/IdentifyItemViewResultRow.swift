//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension IdentifyItemView {

    struct ResultRow: View {

        let result: RemoteSearchResult
        let action: () -> Void

        private var resultTitle: String {
            result.displayTitle
                .appending(" (\(result.premiereDate!.formatted(.dateTime.year())))", if: result.premiereDate != nil)
        }

        var body: some View {
            Button(action: action) {
                HStack {
                    PosterImage(item: result, type: .portrait)
                        .frame(width: 60)
                        .padding()

                    VStack(alignment: .leading) {
                        Text(resultTitle)
                            .font(.headline)
                            .foregroundStyle(Color.primary)

                        if let overview = result.overview {
                            Text(overview)
                                .lineLimit(3)
                                .font(.subheadline)
                                .foregroundStyle(Color.secondary)
                        }
                    }
                }
            }
        }
    }
}
