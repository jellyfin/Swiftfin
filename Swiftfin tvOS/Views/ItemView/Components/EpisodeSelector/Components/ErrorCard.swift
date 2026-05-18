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
        let action: () -> Void

        var body: some View {
            VStack(alignment: .leading) {
                Button {
                    action()
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

        init(error: ErrorMessage, action: @escaping () -> Void = {}) {
            self.error = error
            self.action = action
        }
    }
}
