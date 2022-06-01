//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Introspect
import JellyfinAPI
import SwiftUI

struct ItemView: View {

	@EnvironmentObject
	var itemRouter: ItemCoordinator.Router

	let item: BaseItemDto

	var body: some View {
		Group {
			switch item.itemType {
			case .episode:
				EpisodeItemView()
					.environmentObject(EpisodeItemViewModel(item: item))
			case .series:
				if UIDevice.isIPad {
					iPadOSSeriesItemView()
						.environmentObject(SeriesItemViewModel(item: item))
				} else {
					SeriesItemView()
						.environmentObject(SeriesItemViewModel(item: item))
				}
			case .movie:
				if UIDevice.isIPad {
					iPadOSMovieItemView()
						.environmentObject(MovieItemViewModel(item: item))
				} else {
					MovieItemView()
						.environmentObject(MovieItemViewModel(item: item))
				}
			case .season:
				SeasonItemView()
					.environmentObject(SeasonItemViewModel(item: item))
			default:
				Text("Hello there")
				//                ItemPortraitMainView()
				//                    .environmentObject(ItemViewModel(item: item))
			}
		}
		.navigationBarTitle(item.name ?? "", displayMode: .inline)
	}
}
