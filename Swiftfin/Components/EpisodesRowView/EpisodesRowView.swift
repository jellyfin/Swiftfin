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
	private var viewModel: RowManager
	private let singleSeason: Bool

	init(viewModel: RowManager, singleSeason: Bool = false) {
		self.viewModel = viewModel
		self.singleSeason = singleSeason
	}

	@ViewBuilder
	private var loadingCard: some View {
		VStack(alignment: .leading) {

			Color.gray
				.frame(width: 200, height: 112)
				.cornerRadius(10)

			VStack(alignment: .leading) {
				Text("S-:E-")
					.font(.footnote)
					.foregroundColor(.secondary)
				Text("Placeholder Title")
					.font(.body)
					.padding(.bottom, 1)
					.lineLimit(2)

				Text(String(repeating: "Placeholder", count: 20))
					.font(.caption)
					.foregroundColor(.secondary)
					.fontWeight(.light)
					.lineLimit(3)
					.fixedSize(horizontal: false, vertical: true)
			}

			Spacer()
		}
		.redacted(reason: .placeholder)
		.frame(width: 200)
		.animation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: true), value: 1)
	}

	@ViewBuilder
	private var noEpisodesCard: some View {
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
	}

	@ViewBuilder
	private var headerView: some View {
		if singleSeason {
			HStack {
				Text(viewModel.selectedSeason?.name ?? L10n.season)

				Spacer()
			}
			.font(.title3.weight(.semibold))
			.padding(.horizontal)
			.padding(.top)
		} else {
			HStack {
				Menu {
					ForEach(viewModel.sortedSeasons,
					        id: \.self) { season in
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
						Group {
							Text(viewModel.selectedSeason?.name ?? L10n.unknown)
								.fixedSize()
							Image(systemName: "chevron.down")
						}
						.font(.title3.weight(.semibold))
					}
				}

				Spacer()

				if let selectedSeason = viewModel.selectedSeason, !singleSeason {
					Button {
						itemRouter.route(to: \.item, selectedSeason)
					} label: {
						Image(systemName: "info.circle.fill")
							.font(.title3.weight(.semibold))
					}
				}
			}
			.padding()
		}
	}

	var body: some View {
		VStack(alignment: .leading, spacing: 0) {

			headerView

			ScrollView(.horizontal, showsIndicators: false) {
				HStack(alignment: .top, spacing: 15) {
					if viewModel.isLoading {
						loadingCard
					} else if let selectedSeason = viewModel.selectedSeason {
						if let seasonEpisodes = viewModel.seasonsEpisodes[selectedSeason] {
							if seasonEpisodes.isEmpty {
								noEpisodesCard
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
				.fixedSize(horizontal: false, vertical: true)
			}
		}
	}
}
