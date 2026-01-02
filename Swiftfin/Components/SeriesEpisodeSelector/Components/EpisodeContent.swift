//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension SeriesEpisodeSelector {

    struct EpisodeContent: View {

        @Default(.accentColor)
        private var accentColor

        let title: String
        let subtitle: String
        let description: String
        let action: () -> Void

        @ViewBuilder
        private var subtitleView: some View {
            Text(subtitle)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }

        @ViewBuilder
        private var titleView: some View {
            Text(title)
                .font(.body)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .multilineTextAlignment(.leading)
                .padding(.bottom, 1)
        }

        @ViewBuilder
        private var descriptionView: some View {
            Text(description)
                .font(.caption)
                .fontWeight(.light)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .lineLimit(3, reservesSpace: true)
        }

        var body: some View {
            Button(action: action) {
                VStack(alignment: .leading) {
                    subtitleView

                    titleView

                    descriptionView

                    Text(L10n.seeMore)
                        .font(.caption)
                        .fontWeight(.light)
                        .foregroundStyle(accentColor)
                }
            }
            .foregroundStyle(.primary, .secondary)
        }
    }
}
