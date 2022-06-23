//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import ASCollectionView
import Defaults
import SwiftUI

extension CollectionItemView {

	struct ContentView: View {

		@EnvironmentObject
		var itemRouter: ItemCoordinator.Router
		@ObservedObject
		var viewModel: CollectionItemViewModel
		@Default(.itemViewType)
		private var itemViewType

		var body: some View {
			VStack(alignment: .leading, spacing: 20) {
				if case ItemViewType.compactPoster = itemViewType {
					if let firstTagline = viewModel.playButtonItem?.taglines?.first {
						Text(firstTagline)
							.font(.body)
							.fontWeight(.semibold)
							.lineLimit(2)
							.foregroundColor(.white)
							.padding(.horizontal)
					}

					if let itemOverview = viewModel.item.overview {
						TruncatedTextView(itemOverview,
						                  lineLimit: 4,
						                  font: UIFont.preferredFont(forTextStyle: .footnote)) {
							itemRouter.route(to: \.itemOverview, viewModel.item)
						}
						.fixedSize(horizontal: false, vertical: true)
						.padding(.horizontal)
					}
				}

				// MARK: Genres

				if let genres = viewModel.item.genreItems, !genres.isEmpty {
					PillHStack(title: L10n.genres,
					           items: genres) { genre in
						itemRouter.route(to: \.library, (viewModel: .init(genre: genre), title: genre.title))
					}
				}

				// MARK: Studios

				if let studios = viewModel.item.studios {
					PillHStack(title: L10n.studios,
					           items: studios) { studio in
						itemRouter.route(to: \.library, (viewModel: .init(studio: studio), title: studio.name ?? ""))
					}
				}

				PortraitImageHStack(items: viewModel.similarItems) {
					L10n.items.text
						.fontWeight(.semibold)
						.padding(.bottom)
						.padding(.horizontal)
						.accessibility(addTraits: [.isHeader])
				} selectedAction: { item in
					itemRouter.route(to: \.item, item)
				}
			}
		}
	}
}
