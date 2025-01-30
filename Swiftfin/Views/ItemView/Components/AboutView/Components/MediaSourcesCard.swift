//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

extension ItemView.AboutView {

    struct MediaSourcesCard: View {

        @Default(.accentColor)
        private var accentColor

        @EnvironmentObject
        private var router: ItemCoordinator.Router

        let subtitle: String?
        let source: MediaSourceInfo

        var body: some View {
            Card(title: L10n.media, subtitle: subtitle)
                .content {
                    if let mediaStreams = source.mediaStreams {
                        VStack(alignment: .leading) {
                            Text(mediaStreams.compactMap(\.displayTitle).prefix(4).joined(separator: "\n"))
                                .font(.footnote)

                            if mediaStreams.count > 4 {
                                L10n.seeMore.text
                                    .font(.footnote)
                                    .foregroundColor(accentColor)
                            }
                        }
                    }
                }
                .onSelect {
                    router.route(to: \.mediaSourceInfo, source)
                }
        }
    }
}
