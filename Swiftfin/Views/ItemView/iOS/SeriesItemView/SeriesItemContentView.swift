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
        
        var body: some View {
            VStack(alignment: .leading) {
                
                if case ItemViewType.compactPoster = itemViewType, let itemOverView = viewModel.item.overview {
                    TruncatedTextView(itemOverView,
                                      lineLimit: 4,
                                      font: UIFont.preferredFont(forTextStyle: .footnote)) {
                        itemRouter.route(to: \.itemOverview, viewModel.item)
                    }
                                      .padding(.horizontal)
                                      .padding(.top)
                }

                // MARK: Seasons

                EpisodesRowView(viewModel: viewModel)

                // MARK: Genres

                if let genres = viewModel.item.genreItems, !genres.isEmpty {
                    PillHStackView(title: L10n.genres,
                                   items: genres) { genre in
                        itemRouter.route(to: \.library, (viewModel: .init(genre: genre), title: genre.title))
                    }
                }

                // MARK: Studios

                if let studios = viewModel.item.studios {
                    PillHStackView(title: L10n.studios,
                                   items: studios) { studio in
                        itemRouter.route(to: \.library, (viewModel: .init(studio: studio), title: studio.name ?? ""))
                    }
                }

                // MARK: Episodes

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
