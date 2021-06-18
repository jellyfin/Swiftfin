/* JellyfinPlayer/Swiftfin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import JellyfinAPI
import SwiftUI

struct LibraryFilterView: View {
    @Environment(\.presentationMode)
    var presentationMode
    @Binding
    var filters: LibraryFilters

    @StateObject
    var viewModel: LibraryFilterViewModel

    init(filters: Binding<LibraryFilters>, enabledFilterType: [FilterType]) {
        _filters = filters
        _viewModel = StateObject(wrappedValue: .init(filters: filters.wrappedValue, enabledFilterType: enabledFilterType))
    }

    var body: some View {
        NavigationView {
            ZStack {
                Form {
                    if viewModel.enabledFilterType.contains(.genre) {
                        MultiSelector(label: "Genres",
                                      options: viewModel.allGenres,
                                      optionToString: { $0.name ?? "" },
                                      selected: $viewModel.modifyedFilters.withGenres)
                    }
                    if viewModel.enabledFilterType.contains(.filter) {
                        MultiSelector(label: "Filters",
                                      options: viewModel.allItemFilters,
                                      optionToString: { $0.localized },
                                      selected: $viewModel.modifyedFilters.filters)
                    }
                    if viewModel.enabledFilterType.contains(.tag) {
                        MultiSelector(label: "Tags",
                                      options: viewModel.allTags,
                                      optionToString: { $0 },
                                      selected: $viewModel.modifyedFilters.tags)
                    }
                    if viewModel.enabledFilterType.contains(.sortBy) {
                        MultiSelector(label: "Sort by",
                                      options: viewModel.allSortBys,
                                      optionToString: { $0.localized },
                                      selected: $viewModel.modifyedFilters.sortBy)
                    }
                    if viewModel.enabledFilterType.contains(.sortOrder) {
                        MultiSelector(label: "Sort Order",
                                      options: viewModel.allSortOrders,
                                      optionToString: { $0.localized },
                                      selected: $viewModel.modifyedFilters.sortOrder)
                    }
                }
                if viewModel.isLoading {
                    ProgressView()
                }
            }
            .navigationBarTitle("Filters", displayMode: .inline)
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
                        self.filters = viewModel.modifyedFilters
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Text("Apply")
                    }
                }
            }
        }
    }
}
