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

        let error: JellyfinAPIError
        private var onSelect: () -> Void

        init(error: JellyfinAPIError) {
            self.error = error
            self.onSelect = {}
        }

        func onSelect(perform action: @escaping () -> Void) -> Self {
            copy(modifying: \.onSelect, with: action)
        }

        var body: some View {
            Button {
                onSelect()
            } label: {
                VStack(alignment: .leading) {
                    Color.secondarySystemFill
                        .opacity(0.75)
                        .posterStyle(.landscape)
                        .overlay {
                            Image(systemName: "arrow.clockwise.circle.fill")
                                .font(.system(size: 40))
                        }

                    SeriesEpisodeSelector.EpisodeContent(
                        subHeader: .emptyDash,
                        header: L10n.error,
                        content: error.localizedDescription
                    )
                }
            }
        }
    }
}
