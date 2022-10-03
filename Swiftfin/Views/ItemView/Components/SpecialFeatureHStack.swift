//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ItemView {

    struct SpecialFeaturesHStack: View {

        @EnvironmentObject
        private var router: MainCoordinator.Router

        let items: [BaseItemDto]

        var body: some View {
            PosterHStack(
                title: "Special Features",
                type: .landscape,
                items: items.map { .item($0) }
            )
            .onSelect { item in
                router.route(to: \.videoPlayer, .init(item: item))
            }
        }
    }
}
