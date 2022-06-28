//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import Introspect
import JellyfinAPI
import SwiftUI

// Useless view necessary in tvOS because of iOS's implementation
struct ItemNavigationView: View {
	private let item: BaseItemDto

	init(item: BaseItemDto) {
		self.item = item
	}

	var body: some View {
		ItemView(item: item)
	}
}

struct ItemView: View {

	@Default(.tvOSCinematicViews)
	var tvOSCinematicViews

	private var item: BaseItemDto

	init(item: BaseItemDto) {
		self.item = item
	}

	var body: some View {
		Group {
			switch item.itemType {
			case .movie:
                CinematicMovieItemView(viewModel: MovieItemViewModel(item: item))
			case .episode:
                CinematicEpisodeItemView(viewModel: EpisodeItemViewModel(item: item))
			case .season:
                CinematicSeasonItemView(viewModel: SeasonItemViewModel(item: item))
			case .series:
                CinematicSeriesItemView(viewModel: SeriesItemViewModel(item: item))
			case .boxset, .folder:
				CinematicCollectionItemView(viewModel: CollectionItemViewModel(item: item))
			default:
				Text(L10n.notImplementedYetWithType(item.type ?? ""))
			}
		}
	}
}
