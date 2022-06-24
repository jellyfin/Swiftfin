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

extension SeriesItemView {

	struct ContentView: View {

		@EnvironmentObject
		var itemRouter: ItemCoordinator.Router
		@ObservedObject
		var viewModel: SeriesItemViewModel
		@Default(.itemViewType)
		private var itemViewType
        
        // MARK: Compact Poster Overview
        
        @ViewBuilder
        private var compactPosterOverview: some View {
            if let firstTagline = viewModel.playButtonItem?.taglines?.first {
                Text(firstTagline)
                    .font(.body)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
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
                .padding(.bottom)
            }
        }

		var body: some View {
			VStack(alignment: .leading, spacing: 20) {

                if case ItemViewType.compactPoster = itemViewType {
                    compactPosterOverview
                }
                
                if case ItemViewType.compactLogo = itemViewType {
                    compactPosterOverview
                }

				// MARK: Episodes

				EpisodesRowView(viewModel: viewModel)

				// MARK: Genres

                if let genres = viewModel.item.genreItems, !genres.isEmpty {
                    PillHStack(title: L10n.genres,
                               items: genres) { genre in
                        itemRouter.route(to: \.library, (viewModel: .init(genre: genre), title: genre.title))
                    }
                    
                    Divider()
                }

                // MARK: Studios

                if let studios = viewModel.item.studios, !studios.isEmpty {
                    PillHStack(title: L10n.studios,
                               items: studios) { studio in
                        itemRouter.route(to: \.library, (viewModel: .init(studio: studio), title: studio.name ?? ""))
                    }
                    
                    Divider()
                }
                
                // MARK: Cast and Crew

                if let castAndCrew = viewModel.item.people?.filter { BaseItemPerson.DisplayedType.allCasesRaw.contains($0.type ?? "") },
                !castAndCrew.isEmpty {
                    PortraitImageHStack(title: L10n.castAndCrew,
                                        items: castAndCrew) { person in
                        itemRouter.route(to: \.library, (viewModel: .init(person: person), title: person.title))
                    }
                    
                    Divider()
                }

                // MARK: Similar

                if !viewModel.similarItems.isEmpty {
                    PortraitImageHStack(title: L10n.recommended,
                                        items: viewModel.similarItems) { item in
                        itemRouter.route(to: \.item, item)
                    }
                    
                    Divider()
                }

                ItemView.AboutView(viewModel: viewModel)

				// MARK: Details

				if let informationItems = viewModel.item.createInformationItems(), !informationItems.isEmpty {
					ListDetailsView(title: L10n.information, items: informationItems)
						.padding(.horizontal)
				}
			}
		}
	}
}
