//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct CinematicSeriesItemView: View {

	@EnvironmentObject
	var itemRouter: ItemCoordinator.Router
	@ObservedObject
	var viewModel: SeriesItemViewModel
	@State
	var wrappedScrollView: UIScrollView?
	@Default(.showPosterLabels)
	var showPosterLabels

	var body: some View {
		ZStack {

			ImageView(src: viewModel.item.getBackdropImage(maxWidth: 1920), bh: viewModel.item.getBackdropImageBlurHash())
				.ignoresSafeArea()

			ScrollView {
				VStack(spacing: 0) {

					CinematicItemViewTopRow(viewModel: viewModel,
					                        wrappedScrollView: wrappedScrollView,
					                        title: viewModel.item.name ?? "",
					                        subtitle: nil)
						.focusSection()
						.frame(height: UIScreen.main.bounds.height - 10)

					ZStack(alignment: .topLeading) {

						Color.black.ignoresSafeArea()
							.frame(minHeight: UIScreen.main.bounds.height)

						VStack(alignment: .leading, spacing: 20) {

							CinematicItemAboutView(viewModel: viewModel)

							PortraitItemsRowView(rowTitle: "Seasons",
							                     items: viewModel.seasons,
							                     showItemTitles: showPosterLabels) { season in
								itemRouter.route(to: \.item, season)
							}

							if !viewModel.similarItems.isEmpty {
								PortraitItemsRowView(rowTitle: "Recommended",
								                     items: viewModel.similarItems,
								                     showItemTitles: showPosterLabels) { item in
									itemRouter.route(to: \.item, item)
								}
							}
						}
						.padding(.vertical, 50)
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
