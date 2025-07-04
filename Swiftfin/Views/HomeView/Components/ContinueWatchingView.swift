//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import CollectionHStack
import JellyfinAPI
import SwiftUI

extension HomeView {

    struct ContinueWatchingView: View {

        @Router
        private var router

        @ObservedObject
        var viewModel: HomeViewModel

        // TODO: see how this looks across multiple screen sizes
        //       alongside PosterHStack + landscape
        // TODO: need better handling for iPadOS + portrait orientation
        private var columnCount: CGFloat {
            if UIDevice.isPhone {
                1.5
            } else {
                3.5
            }
        }

        var body: some View {
            CollectionHStack(
                uniqueElements: viewModel.resumeItems,
                columns: columnCount
            ) { item in
                PosterButton(
                    item: item,
                    type: .landscape
                ) { namespace in
                    router.route(to: .item(item: item), in: namespace)
                } label: {
                    if item.type == .episode {
                        PosterButton.EpisodeContentSubtitleContent(item: item)
                    } else {
                        PosterButton.TitleSubtitleContentView(item: item)
                    }
                }
            }
            .clipsToBounds(false)
            .scrollBehavior(.continuousLeadingEdge)
            .contextMenu(for: BaseItemDto.self) { item in
                Button {
                    viewModel.send(.setIsPlayed(true, item))
                } label: {
                    Label(L10n.played, systemImage: "checkmark.circle")
                }

                Button(role: .destructive) {
                    viewModel.send(.setIsPlayed(false, item))
                } label: {
                    Label(L10n.unplayed, systemImage: "minus.circle")
                }
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
