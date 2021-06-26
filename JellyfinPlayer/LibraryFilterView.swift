/* JellyfinPlayer/Swiftfin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import JellyfinAPI
import SwiftUI

struct LibraryFilterView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var filters: LibraryFilters

    @StateObject var viewModel: LibraryFilterViewModel

    init(filters: Binding<LibraryFilters>, enabledFilterType: [FilterType]) {
        _filters = filters
        _viewModel = StateObject(wrappedValue: .init(filters: filters.wrappedValue, enabledFilterType: enabledFilterType))
    }

    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    Form {
                        if viewModel.enabledFilterType.contains(.genre) {
                            MultiSelector(label: "Genres",
                                          options: viewModel.possibleGenres,
                                          optionToString: { $0.name ?? "" },
                                          selected: $viewModel.modifiedFilters.withGenres)
                        }
                        if viewModel.enabledFilterType.contains(.filter) {
                            MultiSelector(label: "Filters",
                                          options: viewModel.possibleItemFilters,
                                          optionToString: { $0.localized },
                                          selected: $viewModel.modifiedFilters.filters)
                        }
                        if viewModel.enabledFilterType.contains(.tag) {
                            MultiSelector(label: "Tags",
                                          options: viewModel.possibleTags,
                                          optionToString: { $0 },
                                          selected: $viewModel.modifiedFilters.tags)
                        }
                        if viewModel.enabledFilterType.contains(.sortBy) {
                            Picker(selection: $viewModel.selectedSortBy, label: Text("Sort by")) {
                                ForEach(viewModel.possibleSortBys, id: \.self) { so in
                                    Text(so.localized).tag(so)
                                }
                            }
                        }
                        if viewModel.enabledFilterType.contains(.sortOrder) {
                            Picker(selection: $viewModel.selectedSortOrder, label: Text("Display order")) {
                                ForEach(viewModel.possibleSortOrders, id: \.self) { so in
                                    Text(so.rawValue).tag(so)
                                }
                            }
                        }
                    }
                    Button {
                        viewModel.resetFilters()
                        self.filters = viewModel.modifiedFilters
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Text("Reset")
                    }
                }
            }
            .navigationBarTitle("Filter Results", displayMode: .inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.updateModifiedFilter()
                        self.filters = viewModel.modifiedFilters
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Text("Apply")
                    }
                }
            }
        }
    }
}
