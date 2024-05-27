//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import SwiftUI

extension OfflineSeriesEpisodeSelector {

    struct EmptyCard: View {

        var body: some View {
            VStack(alignment: .leading) {
                Color.secondarySystemFill
                    .opacity(0.75)
                    .posterStyle(.landscape)

                OfflineSeriesEpisodeSelector.EpisodeContent(
                    subHeader: .emptyDash,
                    header: L10n.noResults,
                    content: L10n.noEpisodesAvailable
                )
                .disabled(true)
            }
        }
    }
}
