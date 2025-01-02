//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import Introspect
import SwiftUI

struct CinematicEpisodeItemView: View {

    @EnvironmentObject
    var itemRouter: ItemCoordinator.Router
    @ObservedObject
    var viewModel: EpisodeItemViewModel
    @State
    var wrappedScrollView: UIScrollView?
    @Default(.showPosterLabels)
    var showPosterLabels

    func generateSubtitle() -> String? {
        guard let seriesName = viewModel.item.seriesName, let episodeLocator = viewModel.item.episodeLocator else {
            return nil
        }

        return "\(seriesName) - \(episodeLocator)"
    }

    var body: some View {
        ZStack {

            ImageView(
                viewModel.item.getBackdropImage(maxWidth: 1920),
                blurHash: viewModel.item.getBackdropImageBlurHash()
            )
            .frame(height: UIScreen.main.bounds.height - 10)
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {

                    CinematicItemViewTopRow(
                        viewModel: viewModel,
                        wrappedScrollView: wrappedScrollView,
                        title: viewModel.item.name ?? "",
                        subtitle: generateSubtitle()
                    )
                    .focusSection()
                    .frame(height: UIScreen.main.bounds.height - 10)

                    ZStack(alignment: .topLeading) {

                        Color.black.ignoresSafeArea()
                            .frame(minHeight: UIScreen.main.bounds.height)

                        VStack(alignment: .leading, spacing: 20) {

                            CinematicItemAboutView(viewModel: viewModel)

                            //							EpisodesRowView(viewModel: viewModel, onlyCurrentSeason: true)
                            //								.focusSection()

                            //							if let seriesItem = viewModel.series {
                            //								PortraitItemsRowView(rowTitle: L10n.series,
                            //								                     items: [seriesItem]) { seriesItem in
                            //									itemRouter.route(to: \.item, seriesItem)
                            //								}
                            //							}

                            //							if !viewModel.similarItems.isEmpty {
                            //								PortraitImageHStack(rowTitle: L10n.recommended,
                            //								                     items: viewModel.similarItems,
                            //								                     showItemTitles: showPosterLabels) { item in
                            //									itemRouter.route(to: \.item, item)
                            //								}
                            //							}

                            ItemDetailsView(viewModel: viewModel)
                        }
                        .padding(.top, 50)
                    }
                }
            }
            .introspectScrollView { scrollView in
                wrappedScrollView = scrollView
            }
            .ignoresSafeArea()
        }
    }
}
