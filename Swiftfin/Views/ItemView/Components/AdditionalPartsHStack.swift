//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

// TODO: make queue for parts

extension ItemView {

    struct AdditionalPartsHStack: View {

        @Router
        private var router

        let items: [BaseItemDto]

        var body: some View {
            PosterHStack(
                title: "Additional Parts",
                type: .landscape,
                items: items
            ) { item, _ in
                guard let mediaSource = item.mediaSources?.first else { return }
                router.route(to: .videoPlayer(item: item, mediaSource: mediaSource))
            }
        }
    }
}
