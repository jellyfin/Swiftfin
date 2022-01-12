//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct EpisodesRowView<RowManager>: View where RowManager: EpisodesRowManager {

	@EnvironmentObject
	var itemRouter: ItemCoordinator.Router
	@ObservedObject
	var viewModel: RowManager
	let onlyCurrentSeason: Bool

	var body: some View {
		VStack(alignment: .leading) {

			Text(viewModel.selectedSeason?.name ?? L10n.episodes)
				.font(.title3)
				.padding(.horizontal, 50)

			ScrollView(.horizontal) {
				ScrollViewReader { reader in
					HStack(alignment: .top) {
						if viewModel.isLoading {
							VStack(alignment: .leading) {

								ZStack {
									Color.secondary.ignoresSafeArea()

									ProgressView()
								}
								.mask(Rectangle().frame(width: 500, height: 280))
								.frame(width: 500, height: 280)

								VStack(alignment: .leading) {
									Text("S-E-")
										.font(.caption)
										.foregroundColor(.secondary)
									Text("--")
										.font(.footnote)
										.padding(.bottom, 1)
									Text("--")
										.font(.caption)
										.fontWeight(.light)
										.lineLimit(4)
								}
								.padding(.horizontal)

								Spacer()
							}
							.frame(width: 500)
							.focusable()
						} else if let selectedSeason = viewModel.selectedSeason {
							if let seasonEpisodes = viewModel.seasonsEpisodes[selectedSeason] {
								if seasonEpisodes.isEmpty {
									VStack(alignment: .leading) {

										Color.secondary
											.mask(Rectangle().frame(width: 500, height: 280))
											.frame(width: 500, height: 280)

										VStack(alignment: .leading) {
											Text("--")
												.font(.caption)
												.foregroundColor(.secondary)
											L10n.noEpisodesAvailable.text
												.font(.footnote)
												.padding(.bottom, 1)
										}
										.padding(.horizontal)

										Spacer()
									}
									.frame(width: 500)
									.focusable()
								} else {
									ForEach(viewModel.seasonsEpisodes[selectedSeason]!, id: \.self) { episode in
										EpisodeRowCard(viewModel: viewModel, episode: episode)
											.id(episode.id)
									}
								}
							}
						}
					}
					.padding(.horizontal, 50)
					.padding(.vertical)
					.onChange(of: viewModel.selectedSeason) { _ in
						if viewModel.selectedSeason?.id == viewModel.item.seasonId {
							reader.scrollTo(viewModel.item.id)
						}
					}
					.onChange(of: viewModel.seasonsEpisodes) { _ in
						if viewModel.selectedSeason?.id == viewModel.item.seasonId {
							reader.scrollTo(viewModel.item.id)
						}
					}
				}
				.edgesIgnoringSafeArea(.horizontal)
			}
		}
	}
}
