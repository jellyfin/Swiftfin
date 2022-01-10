//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct EpisodesRowView: View {

	@EnvironmentObject
	var itemRouter: ItemCoordinator.Router
	@ObservedObject
	var viewModel: EpisodesRowViewModel

	var body: some View {
		VStack(alignment: .leading, spacing: 0) {

			HStack {
				Menu {
					ForEach(Array(viewModel.seasonsEpisodes.keys).sorted(by: { $0.name ?? "" < $1.name ?? "" }), id: \.self) { season in
						Button {
							viewModel.selectedSeason = season
						} label: {
							if season.id == viewModel.selectedSeason?.id {
								Label(season.name ?? "Season", systemImage: "checkmark")
							} else {
								Text(season.name ?? "Season")
							}
						}
					}
				} label: {
					HStack(spacing: 5) {
						Text(viewModel.selectedSeason?.name ?? "Unknown")
							.fontWeight(.semibold)
							.fixedSize()
						Image(systemName: "chevron.down")
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
									Text("S-E-")
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
							if viewModel.seasonsEpisodes[selectedSeason]!.isEmpty {
								VStack(alignment: .leading) {

									Color.gray.ignoresSafeArea()
										.mask(Rectangle().frame(width: 200, height: 112).cornerRadius(10))
										.frame(width: 200, height: 112)

									VStack(alignment: .leading) {
										Text("--")
											.font(.footnote)
											.foregroundColor(.secondary)
										Text("No episodes available")
											.font(.body)
											.padding(.bottom, 1)
											.lineLimit(2)
									}

									Spacer()
								}
								.frame(width: 200)
								.shadow(radius: 4, y: 2)
							} else {
								ForEach(viewModel.seasonsEpisodes[selectedSeason]!, id: \.self) { episode in
									Button {
										itemRouter.route(to: \.item, episode)
									} label: {
										HStack(alignment: .top) {
											VStack(alignment: .leading) {

												ImageView(src: episode.getBackdropImage(maxWidth: 200),
												          bh: episode.getBackdropImageBlurHash())
													.mask(Rectangle().frame(width: 200, height: 112).cornerRadius(10))
													.frame(width: 200, height: 112)
													.overlay {
														if episode.id == viewModel.episodeItemViewModel.item.id {
															RoundedRectangle(cornerRadius: 6)
																.stroke(Color.jellyfinPurple, lineWidth: 4)
														}
													}
													.padding(.top)

												VStack(alignment: .leading) {
													Text(episode.getEpisodeLocator() ?? "")
														.font(.footnote)
														.foregroundColor(.secondary)
													Text(episode.name ?? "")
														.font(.body)
														.padding(.bottom, 1)
														.lineLimit(2)
													Text(episode.overview ?? "")
														.font(.caption)
														.foregroundColor(.secondary)
														.fontWeight(.light)
														.lineLimit(3)
												}

												Spacer()
											}
											.frame(width: 200)
											.shadow(radius: 4, y: 2)
										}
									}
									.buttonStyle(PlainButtonStyle())
									.id(episode.name)
								}
							}
						}
					}
					.padding(.horizontal)
					.onChange(of: viewModel.selectedSeason) { _ in
						if viewModel.selectedSeason?.id == viewModel.episodeItemViewModel.item.seasonId {
							reader.scrollTo(viewModel.episodeItemViewModel.item.name)
						}
					}
					.onChange(of: viewModel.seasonsEpisodes) { _ in
						if viewModel.selectedSeason?.id == viewModel.episodeItemViewModel.item.seasonId {
							reader.scrollTo(viewModel.episodeItemViewModel.item.name)
						}
					}
				}
				.edgesIgnoringSafeArea(.horizontal)
			}
		}
	}
}
