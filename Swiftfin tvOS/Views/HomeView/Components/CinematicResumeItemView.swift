//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension HomeView {

    struct ContinueWatchingView: View {

        @Router
        private var router

        @ObservedObject
        var viewModel: HomeViewModel

        var body: some View {
            PosterHStack(
                title: L10n.continue.localizedCapitalized,
                type: .landscape,
                items: viewModel.resumeItems.elements,
                horizontalInset: 80
            ) { item in
                router.route(to: .item(item: item))
            }
            .posterOverlay(for: BaseItemDto.self) { item in
                LandscapePosterProgressBar(
                    title: item.progressLabel ?? L10n.continue,
                    progress: (item.userData?.playedPercentage ?? 0) / 100
                )
            }
        }
    }
}
