//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension SeriesEpisodeSelector {

    struct EmptyCard: View {

        var body: some View {
            VStack(alignment: .leading) {
                Color.secondarySystemFill
                    .opacity(0.75)
                    .posterStyle(.landscape)

                SeriesEpisodeSelector.EpisodeContent(
                    title: L10n.noResults,
                    subtitle: .emptyDash,
                    description: L10n.noEpisodesAvailable,
                    action: {}
                )
                .disabled(true)
            }
        }
    }
}
