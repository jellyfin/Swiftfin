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
		VStack(alignment: .leading, spacing: 0) {

			HStack {

				if onlyCurrentSeason {
					if let currentSeason = Array(viewModel.seasonsEpisodes.keys).first(where: { $0.id == viewModel.item.id }) {
						Text(currentSeason.name ?? L10n.noTitle)
					}
				} else {
					Menu {
						ForEach(Array(viewModel.seasonsEpisodes.keys).sorted(by: { $0.name ?? "" < $1.name ?? "" }), id: \.self) { season in
							Button {
								viewModel.select(season: season)
							} label: {
								if season.id == viewModel.selectedSeason?.id {
									Label(season.name ?? L10n.season, systemImage: "checkmark")
								} else {
									Text(season.name ?? L10n.season)
								}
							}
						}
					} label: {
						HStack(spacing: 5) {
							Text(viewModel.selectedSeason?.name ?? L10n.unknown)
								.fontWeight(.semibold)
								.fixedSize()
							Image(systemName: "chevron.down")
						}
					}
				}

				Spacer()
			}
			.padding()

			ScrollView(.horizontal, showsIndicators: false) {
				ScrollViewReader { reader in
					HStack(alignment: .top, spacing: 15) {
						if viewModel.isLoading {
							VStack(alignment: .leading) {

								ZStack {
									Color.gray.ignoresSafeArea()

									ProgressView()
								}
								.mask(Rectangle().frame(width: 200, height: 112).cornerRadius(10))
								.frame(width: 200, height: 112)

								VStack(alignment: .leading) {
									Text("S-:E-")
										.font(.footnote)
										.foregroundColor(.secondary)
									Text("--")
										.font(.body)
										.padding(.bottom, 1)
										.lineLimit(2)
								}

								Spacer()
							}
							.frame(width: 200)
							.shadow(radius: 4, y: 2)
						} else if let selectedSeason = viewModel.selectedSeason {
							if let seasonEpisodes = viewModel.seasonsEpisodes[selectedSeason] {
								if seasonEpisodes.isEmpty {
									VStack(alignment: .leading) {

										Color.gray.ignoresSafeArea()
											.mask(Rectangle().frame(width: 200, height: 112).cornerRadius(10))
											.frame(width: 200, height: 112)

										VStack(alignment: .leading) {
											Text("--")
												.font(.footnote)
												.foregroundColor(.secondary)

											L10n.noEpisodesAvailable.text
												.font(.body)
												.padding(.bottom, 1)
												.lineLimit(2)
										}

										Spacer()
									}
									.frame(width: 200)
									.shadow(radius: 4, y: 2)
								} else {
									ForEach(seasonEpisodes, id: \.self) { episode in
										EpisodeRowCard(viewModel: viewModel, episode: episode)
											.id(episode.id)
									}
								}
							}
						}
					}
					.padding(.horizontal)
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
