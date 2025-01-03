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

extension IdentifyItemView {

    struct RemoteSearchResultRow: View {

        // MARK: - Remote Search Result Variable

        let result: RemoteSearchResult

        // MARK: - Remote Search Result Action

        let onSelect: () -> Void

        // MARK: - Result Title

        private var resultTitle: String {
            result.displayTitle
                .appending(" (\(result.premiereDate!.formatted(.dateTime.year())))", if: result.premiereDate != nil)
        }

        // MARK: - Body

        var body: some View {
            ListRow {
                IdentifyItemView.resultImage(URL(string: result.imageURL))
                    .frame(width: 60)
            } content: {
                VStack(alignment: .leading) {
                    Text(resultTitle)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    if let overview = result.overview {
                        Text(overview)
                            .lineLimit(3)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onSelect(perform: onSelect)
            .isSeparatorVisible(false)
        }
    }
}
