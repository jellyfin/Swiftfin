/* JellyfinPlayer/Swiftfin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import SwiftUI
import JellyfinAPI

struct LibraryFilterView: View {
    @Binding var filter: LibraryFilters

    var body: some View {
        EmptyView()
        /*
        NavigationView {
            LoadingView(isShowing: $isLoading) {
                Form {
                    Toggle("Only show unplayed items", isOn: $onlyUnplayed)
                        .onChange(of: onlyUnplayed) { value in
                            if value {
                                filter.filterTypes.append(.isUnplayed)
                            } else {
                                filter.filterTypes.removeAll { $0 == .isUnplayed }
                            }
                        }
                    MultiSelector(label: "Genres",
                                  options: allGenres,
                                  optionToString: { $0.name },
                                  selected: $selectedGenres)
                        .onChange(of: selectedGenres) { genres in
                            filter.genres = genres.map(\.id)
                        }
                    MultiSelector(label: "Parental Ratings",
                                  options: allRatings,
                                  optionToString: { $0.name },
                                  selected: $selectedRatings)
                        .onChange(of: selectedRatings) { ratings in
                            filter.officialRatings = ratings.map(\.id)
                        }

                    Section(header: Text("Sort settings")) {
                        Picker("Sort by", selection: $sortBySelection) {
                            Text("Name").tag("SortName")
                            Text("Date Added").tag("DateCreated")
                            Text("Date Played").tag("DatePlayed")
                            Text("Date Released").tag("PremiereDate")
                            Text("Runtime").tag("Runtime")
                        }.onChange(of: sortBySelection) { value in
                            guard let sort = SortType(rawValue: value) else { return }
                            filter.sort = sort
                        }
                        Picker("Sort order", selection: $sortOrder) {
                            Text("Ascending").tag("Ascending")
                            Text("Descending").tag("Descending")
                        }.onChange(of: sortOrder) { order in
                            guard let asc = ASC(rawValue: order) else { return }
                            filter.asc = asc
                        }
                    }
                }
            }.onAppear(perform: onAppear)
                .navigationBarTitle("Filters", displayMode: .inline)
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarLeading) {
                        Button {
                            presentationMode.wrappedValue.dismiss()
                        } label: {
                            HStack {
                                Text("Back").font(.callout)
                            }
                        }
                    }
                }
        }
         */
    }
}
