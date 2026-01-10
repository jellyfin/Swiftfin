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

        private var onSelect: () -> Void

        init() {
            self.onSelect = {}
        }

        func onSelect(perform action: @escaping () -> Void) -> Self {
            copy(modifying: \.onSelect, with: action)
        }

        var body: some View {
            VStack(alignment: .leading) {
                Button {
                    onSelect()
                } label: {
                    Color.secondarySystemFill
                        .opacity(0.75)
                        .posterStyle(.landscape)
                        .overlay {
                            ProgressView()
                        }
                }
                .buttonStyle(.card)
                .posterShadow()

                SeriesEpisodeSelector.EpisodeContent(
                    subHeader: String.random(count: 7 ..< 12),
                    header: String.random(count: 10 ..< 20),
                    content: String.random(count: 20 ..< 80)
                )
                .redacted(reason: .placeholder)
            }
        }
    }
}
