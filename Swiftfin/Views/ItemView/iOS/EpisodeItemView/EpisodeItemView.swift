//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct EpisodeItemView: View {

	@EnvironmentObject
	var itemRouter: ItemCoordinator.Router
	@ObservedObject
	var viewModel: EpisodeItemViewModel

	// MARK: landscapeShelfItem

	@ViewBuilder
	private var landscapeShelfView: some View {
		HStack {
			VStack(alignment: .leading) {
				Text(viewModel.item.seriesName ?? "--")
					.font(.headline)
					.fontWeight(.semibold)
					.padding(.horizontal)
					.foregroundColor(.secondary)

				Text(viewModel.item.displayName)
					.font(.title2)
					.fontWeight(.bold)
					.multilineTextAlignment(.center)
					.fixedSize(horizontal: false, vertical: true)
					.padding(.horizontal)

				HStack(spacing: 10) {
					if let episodeLocation = viewModel.item.getSeasonEpisodeLocator() {
						Text(episodeLocation)
					}

					if let runtime = viewModel.item.getItemRuntime() {
						Text(runtime)
					}

					// TODO: Change to premiere date
					if let productionYear = viewModel.item.productionYear {
						Text(String(productionYear))
					}
				}
				.font(.subheadline)
				.foregroundColor(.secondary)
				.padding(.horizontal)
			}

			Spacer(minLength: 0)

            ItemView.PlayButton(viewModel: viewModel)
				.padding(.horizontal)
		}
	}

	var body: some View {
        NavBarOffsetScrollView(headerHeight: 10) {
            ContentView(viewModel: viewModel)
        }
	}
}
