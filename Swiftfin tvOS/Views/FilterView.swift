//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct FilterView: View {

    // MARK: - Observed Objects

    @ObservedObject
    var viewModel: FilterViewModel

    // MARK: - Filter Type

    let type: ItemFilterType

    // MARK: - Filter Sources

    private var filterSource: [AnyItemFilter] {
        viewModel.allFilters[keyPath: type.collectionAnyKeyPath]
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
            viewModel.send(.reset(.sortBy))
            viewModel.send(.reset(.sortOrder))
        }) {
            HStack {
                Image(systemName: "arrow.clockwise")
                Text(L10n.reset)
                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .disabled(!viewModel.isFilterSelected(type: .sortBy) && !viewModel.isFilterSelected(type: .sortOrder))

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
                                viewModel.send(.update(.sortBy, [item]))
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
                                viewModel.send(.update(.sortOrder, [item]))
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
            viewModel.send(.reset(.traits))
            viewModel.send(.reset(.genres))
            viewModel.send(.reset(.years))
        }) {
            HStack {
                Image(systemName: "arrow.clockwise")
                Text(L10n.reset)
                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .disabled(!viewModel.isFilterSelected(type: .traits) && !viewModel.isFilterSelected(type: .genres) && !viewModel
            .isFilterSelected(type: .years))

        Section {
            ForEach(filterSource, id: \.hashValue) { item in
                ListRowToggleCheckbox(
                    item.displayTitle,
                    isOn: Binding(
                        get: {
                            viewModel.currentFilters[keyPath: type.collectionAnyKeyPath]
                                .contains(where: { $0.hashValue == item.hashValue })
                        },
                        set: { isSelected in
                            let currentSelection = viewModel.currentFilters[keyPath: type.collectionAnyKeyPath]
                            if isSelected {
                                let newSelection = currentSelection + [item]
                                viewModel.send(.update(type, newSelection))
                            } else {
                                let newSelection = currentSelection.filter { $0.hashValue != item.hashValue }
                                viewModel.send(.update(type, newSelection))
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
                        let genreValues = newGenres.compactMap { filter in
                            ItemGenre(stringLiteral: filter.value)
                        }
                        viewModel.send(.update(.genres, genreValues.map(\.asAnyItemFilter)))
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
                        let yearValues = newYears.compactMap { filter in
                            ItemYear(from: filter)
                        }
                        viewModel.send(.update(.years, yearValues.map(\.asAnyItemFilter)))
                    }
                )
            )
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
