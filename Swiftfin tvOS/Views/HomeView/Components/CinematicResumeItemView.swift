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

    struct CinematicResumeView: View {

        @Router
        private var router

        @ObservedObject
        var viewModel: HomeViewModel

        private func itemSelectorImageSource(for item: BaseItemDto) -> ImageSource {
            if item.type == .episode {
                return item.seriesImageSource(
                    .logo,
                    maxWidth: UIScreen.main.bounds.width * 0.4,
                    maxHeight: 200
                )
            } else {
                return item.imageSource(
                    .logo,
                    maxWidth: UIScreen.main.bounds.width * 0.4,
                    maxHeight: 200
                )
            }
        }

        var body: some View {
            CinematicItemSelector(items: viewModel.resumeItems.elements)
                .topContent { item in
                    ImageView(itemSelectorImageSource(for: item))
                        .placeholder { _ in
                            EmptyView()
                        }
                        .failure {
                            Text(item.displayTitle)
                                .font(.largeTitle)
                                .fontWeight(.semibold)
                        }
                        .edgePadding(.leading)
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 200, alignment: .bottomLeading)
                }
                .content { item in
                    // TODO: clean up
                    if item.type == .episode {
                        PosterButton<BaseItemDto>.EpisodeContentSubtitleContent.Subtitle(item: item)
                    } else {
                        Text(" ")
                    }
                }
                .onSelect { item in
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
