//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension HomeView {

    struct ContinueWatchingView: View {

        @EnvironmentObject
        private var router: HomeCoordinator.Router
        @ObservedObject
        var viewModel: HomeViewModel

        var body: some View {
            PosterHStack(title: "", type: .landscape, items: viewModel.resumeItems)
                .scaleItems(1.5)
                .onSelect { item in
                    router.route(to: \.item, item)
                }
                .contextMenu { item in
                    Button(role: .destructive) {
                        viewModel.removeItemFromResume(item)
                    } label: {
                        Label(L10n.removeFromResume, systemImage: "minus.circle")
                    }
                }
                .imageOverlay { item in
                    LandscapePosterProgressBar(
                        title: item.progress ?? L10n.continue,
                        progress: (item.userData?.playedPercentage ?? 0) / 100
                    )
                }
        }
    }
}
