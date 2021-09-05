//
 /* 
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import SwiftUI
import JellyfinAPI

struct ItemViewBody: View {
    
    @EnvironmentObject private var viewModel: ItemViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            
            // MARK: Overview
            Text(viewModel.item.overview ?? "")
                .font(.footnote)
                .padding(.horizontal, 16)
                .padding(.vertical, 3)
            
            // MARK: Seasons
            if let seriesViewModel = viewModel as? SeriesItemViewModel {
                PortraitImageHStackView(items: seriesViewModel.seasons,
                                        maxWidth: 150,
                                        topBarView: {
                                            Text("Seasons")
                                                .font(.callout)
                                                .fontWeight(.semibold)
                                                .padding(.top, 3)
                                                .padding(.leading, 16)
                                        }, navigationView: { season in
                                            ItemNavigationView(item: season)
                                        })
            }
            
            // MARK: Genres
            PillHStackView(title: "Genres",
                           items: viewModel.item.genreItems ?? []) { genre in
                LibraryView(viewModel: .init(genre: genre), title: genre.title)
            }
            
            // MARK: Studios
            if let studios = viewModel.item.studios {
                PillHStackView(title: "Studios",
                               items: studios) { studio in
                    LibraryView(viewModel: .init(studio: studio), title: studio.name ?? "")
                }
            }
            
            // MARK: Cast & Crew
            if let castAndCrew = viewModel.item.people {
                PortraitImageHStackView(items: castAndCrew.filter({ BaseItemPerson.DisplayedType.allCasesRaw.contains($0.type ?? "") }),
                                        maxWidth: 150,
                                        topBarView: {
                                            Text("Cast & Crew")
                                                .font(.callout)
                                                .fontWeight(.semibold)
                                                .padding(.top, 3)
                                                .padding(.leading, 16)
                                        },
                                        navigationView: { person in
                                            LibraryView(viewModel: .init(person: person), title: person.title)
                                        })
            }

            // MARK: More Like This
            if !viewModel.similarItems.isEmpty {
                PortraitImageHStackView(items: viewModel.similarItems,
                                        maxWidth: 150,
                                        topBarView: {
                                            Text("More Like This")
                                                .font(.callout)
                                                .fontWeight(.semibold)
                                                .padding(.top, 3)
                                                .padding(.leading, 16)
                                        },
                                        navigationView: { item in
                                            ItemNavigationView(item: item)
                                        })
            }
        }
    }
}
