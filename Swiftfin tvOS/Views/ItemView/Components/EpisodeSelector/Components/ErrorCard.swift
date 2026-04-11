//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension SeriesEpisodeSelector {

    struct ErrorCard: View {

        let error: ErrorMessage
        private var onSelect: () -> Void

        init(error: ErrorMessage) {
            self.error = error
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
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 40))
                        }
                }
                .buttonStyle(.card)
                .posterShadow()

                SeriesEpisodeSelector.EpisodeContent(
                    subHeader: .emptyDash,
                    header: L10n.error,
                    content: error.localizedDescription
                )
            }
        }
    }
}
