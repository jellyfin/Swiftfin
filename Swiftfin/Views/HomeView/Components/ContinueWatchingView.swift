//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
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
            PosterHStack(
                type: .landscape,
                items: viewModel.resumeItems.map { .item($0) }
            )
            .scaleItems(1.5)
            .contextMenu { state in
                if case let PosterButtonType.item(item) = state {
                    Button {
                        viewModel.markItemPlayed(item)
                    } label: {
                        Label(L10n.played, systemImage: "checkmark.circle")
                    }

                    Button(role: .destructive) {
                        viewModel.markItemUnplayed(item)
                    } label: {
                        Label(L10n.unplayed, systemImage: "minus.circle")
                    }
                }
            }
            .imageOverlay { state in
                if case let PosterButtonType.item(item) = state {
                    LandscapePosterProgressBar(
                        title: item.progressLabel ?? L10n.continue,
                        progress: (item.userData?.playedPercentage ?? 0) / 100
                    )
                }
            }
            .onSelect { item in
                router.route(to: \.item, item)
            }
        }
    }
}
