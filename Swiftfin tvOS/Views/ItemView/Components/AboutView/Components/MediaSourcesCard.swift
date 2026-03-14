//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ItemView.AboutView {

    struct MediaSourcesCard: View {

        @Router
        private var router

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
                                Text(L10n.seeMore)
                                    .font(.footnote)
                            }
                        }
                    }
                }
                .onSelect {
                    router.route(to: .mediaSourceInfo(source: source))
                }
        }
    }
}
