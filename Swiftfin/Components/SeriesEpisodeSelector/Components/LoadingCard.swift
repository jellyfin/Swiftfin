//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension SeriesEpisodeSelector {

    struct LoadingCard: View {

        var body: some View {
            VStack(alignment: .leading) {
                Color.secondarySystemFill
                    .opacity(0.75)
                    .posterStyle(.landscape)

                SeriesEpisodeSelector.EpisodeContent(
                    title: String.random(count: 10 ..< 20),
                    subtitle: String.random(count: 7 ..< 12),
                    description: String.random(count: 20 ..< 80),
                    action: {}
                )
                .redacted(reason: .placeholder)
            }
        }
    }
}
