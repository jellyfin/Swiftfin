//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension SeriesEpisodeSelector {

    struct EpisodeContent: View {

        @Default(.accentColor)
        private var accentColor

        let header: String
        let subHeader: String
        let content: String
        let action: () -> Void

        @ViewBuilder
        private var subHeaderView: some View {
            Text(subHeader)
                .font(.footnote)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }

        @ViewBuilder
        private var headerView: some View {
            Text(header)
                .font(.body)
                .foregroundColor(.primary)
                .lineLimit(1)
                .multilineTextAlignment(.leading)
                .padding(.bottom, 1)
        }

        @ViewBuilder
        private var contentView: some View {
            Text(content)
                .font(.caption)
                .fontWeight(.light)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
                .lineLimit(3, reservesSpace: true)
        }

        var body: some View {
            Button(action: action) {
                VStack(alignment: .leading) {
                    subHeaderView

                    headerView

                    contentView

                    Text(L10n.seeMore)
                        .font(.caption)
                        .fontWeight(.light)
                        .foregroundStyle(accentColor)
                }
            }
        }
    }
}
