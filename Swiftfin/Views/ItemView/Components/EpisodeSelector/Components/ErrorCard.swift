//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension SeriesEpisodeSelector {

    struct ErrorCard: View {

        let error: ErrorMessage
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                VStack(alignment: .leading) {
                    Color.secondarySystemFill
                        .opacity(0.75)
                        .posterStyle(.landscape)
                        .overlay {
                            Image(systemName: "arrow.clockwise.circle.fill")
                                .font(.system(size: 40))
                        }

                    SeriesEpisodeSelector.EpisodeContent(
                        header: L10n.error,
                        subHeader: .emptyDash,
                        content: error.localizedDescription,
                        action: action
                    )
                }
            }
        }
    }
}
