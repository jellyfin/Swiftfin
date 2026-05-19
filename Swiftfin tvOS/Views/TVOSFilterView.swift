//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

#if os(tvOS)
struct TVOSFilterView: View {

    // MARK: - Observed Objects

    @ObservedObject
    var viewModel: FilterViewModel

    // MARK: - Filter Type

    let type: ItemFilterType

    // MARK: - Filter Sources

    private var filterSource: [AnyItemFilter] {
        viewModel.allFilters.traits.map(\.asAnyItemFilter)
    }

    // MARK: - Subtitle Helpers

    private var selectedGenresSubtitle: String {
        let selectedGenres = viewModel.currentFilters.genres.map(\.asAnyItemFilter)
        if selectedGenres.isEmpty {
            return L10n.none
        } else if selectedGenres.count == 1 {
            return selectedGenres.first?.displayTitle ?? L10n.none
        } else {
            return "\(selectedGenres.count) selected"
        }
    }

    private var selectedYearsSubtitle: String {
        let selectedYears = viewModel.currentFilters.years.map(\.asAnyItemFilter)
        if selectedYears.isEmpty {
            return L10n.none
        } else if selectedYears.count == 1 {
            return selectedYears.first?.displayTitle ?? L10n.none
        } else {
            return "\(selectedYears.count) selected"
        }
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            HStack {
                Spacer()
                Form {
                    contentView
                }
                .frame(maxWidth: .infinity)
                .frame(width: geometry.size.width * 0.5)
                .scrollClipDisabled()
                Spacer()
            }
            .navigationTitle(type.displayTitle)
        }
    }

    // MARK: - Filter Content

    @ViewBuilder
    private var contentView: some View {
        if type == .sortBy {
            // Special case for sort: show both sortBy and sortOrder
            sortContentView
        } else if type == .traits {
            // Special case for filters: show both traits and genres
            filtersContentView
        } else {
            Section {
                Text(L10n.none)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
    }

    // MARK: - Sort Content View

    @ViewBuilder
    private var sortContentView: some View {
        Button(action: {
            viewModel.reset(filterType: .sortBy)
        }) {
            HStack {
                Image(systemName: "arrow.clockwise")
                Text(L10n.reset)
                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .disabled(!viewModel.isFilterSelected(type: .sortBy))

        Section {
            ForEach(viewModel.allFilters.sortBy.map(\.asAnyItemFilter), id: \.hashValue) { item in
                ListRowToggleCheckbox(
                    item.displayTitle,
                    isOn: Binding(
                        get: {
                            viewModel.currentFilters.sortBy.contains(where: { $0.asAnyItemFilter.hashValue == item.hashValue })
                        },
                        set: { isSelected in
                            if isSelected {
                                viewModel.currentFilters.sortBy = [ItemSortBy(from: item)]
                            }
                        }
                    )
                )
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }

        Section {
            ForEach(viewModel.allFilters.sortOrder.map(\.asAnyItemFilter), id: \.hashValue) { item in
                ListRowToggleCheckbox(
                    item.displayTitle,
                    isOn: Binding(
                        get: {
                            viewModel.currentFilters.sortOrder.contains(where: { $0.asAnyItemFilter.hashValue == item.hashValue })
                        },
                        set: { isSelected in
                            if isSelected {
                                viewModel.currentFilters.sortOrder = [ItemSortOrder(from: item)]
                            }
                        }
                    )
                )
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        } header: {
            HStack {
                Text(L10n.order.uppercased())
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
    }

    // MARK: - Filters Content View

    @ViewBuilder
    private var filtersContentView: some View {

        Button(action: {
            viewModel.reset(filterType: .traits)
            viewModel.reset(filterType: .genres)
            viewModel.reset(filterType: .years)
        }) {
            HStack {
                Image(systemName: "arrow.clockwise")
                Text(L10n.reset)
                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .disabled(!viewModel.isFilterSelected(type: .traits) && !viewModel.isFilterSelected(type: .genres) && !viewModel.isFilterSelected(type: .years))

        Section {
            ForEach(filterSource, id: \.hashValue) { item in
                ListRowToggleCheckbox(
                    item.displayTitle,
                    isOn: Binding(
                        get: {
                            viewModel.currentFilters.traits.contains(where: { $0.asAnyItemFilter.hashValue == item.hashValue })
                        },
                        set: { isSelected in
                            let currentSelection = viewModel.currentFilters.traits
                            if isSelected {
                                viewModel.currentFilters.traits = currentSelection + [ItemTrait(from: item)]
                            } else {
                                viewModel.currentFilters.traits = currentSelection.filter { $0.asAnyItemFilter.hashValue != item.hashValue }
                            }
                        }
                    )
                )
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }

        Section {
            ListRowMenu(
                L10n.genres,
                subtitle: selectedGenresSubtitle,
                items: viewModel.allFilters.genres.map(\.asAnyItemFilter),
                selection: Binding(
                    get: { viewModel.currentFilters.genres.map(\.asAnyItemFilter) },
                    set: { newGenres in
                        viewModel.currentFilters.genres = newGenres.compactMap { filter in
                            ItemGenre(from: filter)
                        }
                    }
                )
            )
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)

            ListRowMenu(
                L10n.years,
                subtitle: selectedYearsSubtitle,
                items: viewModel.allFilters.years.map(\.asAnyItemFilter),
                selection: Binding(
                    get: { viewModel.currentFilters.years.map(\.asAnyItemFilter) },
                    set: { newYears in
                        viewModel.currentFilters.years = newYears.compactMap { filter in
                            ItemYear(from: filter)
                        }
                    }
                )
            )
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
#endif
