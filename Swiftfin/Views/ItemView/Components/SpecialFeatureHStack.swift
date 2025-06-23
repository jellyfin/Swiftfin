//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import OrderedCollections
import SwiftUI

extension ItemView {

    struct SpecialFeaturesHStack: View {

        @Router
        private var router

        let items: [BaseItemDto]

        var body: some View {
            PosterHStack(
                title: L10n.specialFeatures,
                type: .landscape,
                items: items
            )
            .onSelect { item in
                guard let mediaSource = item.mediaSources?.first else { return }
                router.route(to: .videoPlayer(manager: OnlineVideoPlayerManager(item: item, mediaSource: mediaSource)))
            }
        }
    }
}
