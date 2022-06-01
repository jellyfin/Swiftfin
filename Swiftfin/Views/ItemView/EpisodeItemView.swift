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
	@EnvironmentObject
	private var viewModel: EpisodeItemViewModel

	// MARK: Play Button

	@ViewBuilder
	private var playButton: some View {
		Button {
			if let selectedVideoPlayerViewModel = viewModel.selectedVideoPlayerViewModel {
				itemRouter.route(to: \.videoPlayer, selectedVideoPlayerViewModel)
			} else {
				LogManager.log.error("Attempted to play item but no playback information available")
			}
		} label: {
			ZStack {
				Rectangle()
					.foregroundColor(Color(UIColor.systemPurple))
					.frame(maxWidth: 300, maxHeight: 50)
					.frame(height: 50)
					.cornerRadius(10)

				HStack {
					Image(systemName: "play.fill")
						.font(.system(size: 20))
					Text(viewModel.playButtonText())
						.font(.callout)
						.fontWeight(.semibold)
				}
				.foregroundColor(viewModel.playButtonItem == nil ? Color(UIColor.secondaryLabel) : Color.white)
			}
		}
		.contextMenu {
			if viewModel.playButtonItem != nil, viewModel.item.userData?.playbackPositionTicks ?? 0 > 0 {
				Button {
					if let selectedVideoPlayerViewModel = viewModel.selectedVideoPlayerViewModel {
						selectedVideoPlayerViewModel.injectCustomValues(startFromBeginning: true)
						itemRouter.route(to: \.videoPlayer, selectedVideoPlayerViewModel)
					} else {
						LogManager.log.error("Attempted to play item but no playback information available")
					}
				} label: {
					Label(L10n.playFromBeginning, systemImage: "gobackward")
				}
			}
		}
	}

	// MARK: portraitShelfItem

	@ViewBuilder
	private var portraitShelfView: some View {
		Text(viewModel.item.seriesName ?? "--")
			.font(.headline)
			.fontWeight(.semibold)
			.padding(.horizontal)
			.foregroundColor(.secondary)

		Text(viewModel.getItemDisplayName())
			.font(.title2)
			.fontWeight(.bold)
			.multilineTextAlignment(.center)
			.fixedSize(horizontal: false, vertical: true)
			.padding(.horizontal)

		HStack(spacing: 10) {
			if let episodeLocation = viewModel.item.getEpisodeLocator() {
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

		playButton
	}

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

				Text(viewModel.getItemDisplayName())
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

			playButton
				.padding(.horizontal)
		}
	}

	var body: some View {
		GeometryReader { geometry in
			NavBarOffsetScrollView(headerHeight: 10) {
				VStack {

					ImageView(viewModel.item.getPrimaryImage(maxWidth: 500),
					          blurHash: viewModel.item.getPrimaryImageBlurHash())
						.cornerRadius(10)
						.aspectRatio(1.77, contentMode: .fit)
						.frame(maxWidth: UIDevice.isIPad ? geometry.size.width / 2 : 600)
						.padding(.horizontal)

					VStack(spacing: 10) {

						if UIDevice.isLandscape {
							landscapeShelfView
						} else {
							portraitShelfView
						}

						// MARK: Overview

						if let itemOverview = viewModel.item.overview {
							HStack {
								TruncatedTextView(itemOverview,
								                  lineLimit: 5,
								                  font: UIFont.preferredFont(forTextStyle: .footnote)) {
									itemRouter.route(to: \.itemOverview, viewModel.item)
								}
								.fixedSize(horizontal: false, vertical: true)
								.padding(.top)
								.padding(.horizontal)

								Spacer(minLength: 0)
							}
						}

						// MARK: Genres

						if let genres = viewModel.item.genreItems, !genres.isEmpty {
							PillHStackView(title: L10n.genres,
							               items: genres,
							               selectedAction: { genre in
							               	itemRouter.route(to: \.library, (viewModel: .init(genre: genre), title: genre.title))
							               })
							               .padding(.bottom)
						}

						if let studios = viewModel.item.studios {
							PillHStackView(title: L10n.studios,
							               items: studios) { studio in
								itemRouter.route(to: \.library, (viewModel: .init(studio: studio), title: studio.name ?? ""))
							}
							.padding(.bottom)
						}

						if let castAndCrew = viewModel.item.people, !castAndCrew.isEmpty {
							PortraitImageHStackView(items: castAndCrew
								.filter { BaseItemPerson.DisplayedType.allCasesRaw.contains($0.type ?? "") },
								topBarView: {
									L10n.castAndCrew.text
										.fontWeight(.semibold)
										.padding(.bottom)
										.padding(.horizontal)
										.accessibility(addTraits: [.isHeader])
								},
								selectedAction: { person in
									itemRouter.route(to: \.library,
									                 (viewModel: .init(person: person), title: person.title))
								})
						}

						// MARK: Details

						HStack {
							ListDetailsView(title: L10n.information, items: viewModel.item.createInformationItems())

							Spacer(minLength: 0)
						}
						.padding(.horizontal)
					}
				}
			}
		}
	}
}
