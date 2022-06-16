//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

struct iPadOSSeriesItemView: View {

	@EnvironmentObject
	var itemRouter: ItemCoordinator.Router
	@EnvironmentObject
	private var viewModel: SeriesItemViewModel

	// MARK: portraitHeaderView

	@ViewBuilder
	var portraitHeaderView: some View {
		ImageView(viewModel.item.getBackdropImage(maxWidth: Int(UIScreen.main.bounds.width)),
		          blurHash: viewModel.item.getBackdropImageBlurHash())
	}

	// MARK: portraitStaticOverlayView

	@ViewBuilder
	var portraitStaticOverlayView: some View {
		iPadOSLandscapeOverlayView(viewModel: viewModel)
	}

	// MARK: innerBody

	var innerBody: some View {
		VStack(alignment: .leading) {

			// MARK: Seasons

			EpisodesRowView(viewModel: viewModel)

			// MARK: Genres

			if let genres = viewModel.item.genreItems, !genres.isEmpty {
				PillHStackView(title: L10n.genres,
				               items: genres,
				               selectedAction: { genre in
				               	itemRouter.route(to: \.library, (viewModel: .init(genre: genre), title: genre.title))
				               })
				               .padding(.bottom)
			}

			// MARK: Studios

			if let studios = viewModel.item.studios {
				PillHStackView(title: L10n.studios,
				               items: studios) { studio in
					itemRouter.route(to: \.library, (viewModel: .init(studio: studio), title: studio.name ?? ""))
				}
				.padding(.bottom)
			}

			// MARK: Cast

			if let castAndCrew = viewModel.item.people, !castAndCrew.isEmpty {
				PortraitImageHStackView(items: castAndCrew.filter { BaseItemPerson.DisplayedType.allCasesRaw.contains($0.type ?? "") },
				                        topBarView: {
				                        	L10n.castAndCrew.text
				                        		.fontWeight(.semibold)
				                        		.padding(.bottom)
				                        		.padding(.horizontal)
				                        		.accessibility(addTraits: [.isHeader])
				                        },
				                        selectedAction: { person in
				                        	itemRouter.route(to: \.library, (viewModel: .init(person: person), title: person.title))
				                        })
			}

			// MARK: Recommended

			if !viewModel.similarItems.isEmpty {
				PortraitImageHStackView(items: viewModel.similarItems,
				                        topBarView: {
				                        	L10n.recommended.text
				                        		.fontWeight(.semibold)
				                        		.padding(.bottom)
				                        		.padding(.horizontal)
				                        		.accessibility(addTraits: [.isHeader])
				                        },
				                        selectedAction: { item in
				                        	itemRouter.route(to: \.item, item)
				                        })
			}

			// MARK: About

            ItemView.AboutView(viewModel: viewModel)
				.padding(.bottom)

			// MARK: Details

			if let informationItems = viewModel.item.createInformationItems(), !informationItems.isEmpty {
				ListDetailsView(title: L10n.information, items: informationItems)
					.padding(.horizontal)
			}
		}
	}

	var body: some View {
		ParallaxHeaderScrollView(header: portraitHeaderView,
		                         staticOverlayView: portraitStaticOverlayView,
		                         overlayAlignment: .bottomLeading,
		                         headerHeight: UIScreen.main.bounds.height * 0.8) {
			innerBody
		}
	}
}
