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
                VStack {
                    contentView
                }
                .frame(maxWidth: .infinity)
                .frame(width: geometry.size.width * 0.5)
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
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .disabled(!viewModel.isFilterSelected(type: .sortBy) && !viewModel.isFilterSelected(type: .sortOrder))

        Divider()

        Section {
            ForEach(viewModel.allFilters.sortBy.map(\.asAnyItemFilter), id: \.hashValue) { item in
                Button(action: {
                    viewModel.send(.update(.sortBy, [item]))
                }) {
                    HStack {
                        Text(item.displayTitle)
                        Spacer()
                        if viewModel.currentFilters.sortBy.contains(where: { $0.asAnyItemFilter.hashValue == item.hashValue }) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.accentColor)
                        } else {
                            Image(systemName: "circle")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                }
            }
        }

        Section {
            ForEach(viewModel.allFilters.sortOrder.map(\.asAnyItemFilter), id: \.hashValue) { item in
                Button(action: {
                    viewModel.send(.update(.sortOrder, [item]))
                }) {
                    HStack {
                        Text(item.displayTitle)
                        Spacer()
                        if viewModel.currentFilters.sortOrder.contains(where: { $0.asAnyItemFilter.hashValue == item.hashValue }) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.accentColor)
                        } else {
                            Image(systemName: "circle")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                }
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
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .disabled(!viewModel.isFilterSelected(type: .traits) && !viewModel.isFilterSelected(type: .genres) && !viewModel
            .isFilterSelected(type: .years))

        Divider()

        Section {
            ForEach(filterSource, id: \.hashValue) { item in
                Button(action: {
                    if type.selectorType == .single {
                        viewModel.send(.update(type, [item]))
                    } else {
                        let currentSelection = viewModel.currentFilters[keyPath: type.collectionAnyKeyPath]
                        if currentSelection.contains(where: { $0.hashValue == item.hashValue }) {
                            let newSelection = currentSelection.filter { $0.hashValue != item.hashValue }
                            viewModel.send(.update(type, newSelection))
                        } else {
                            let newSelection = currentSelection + [item]
                            viewModel.send(.update(type, newSelection))
                        }
                    }
                }) {
                    HStack {
                        Text(item.displayTitle)
                        Spacer()
                        if viewModel.currentFilters[keyPath: type.collectionAnyKeyPath]
                            .contains(where: { $0.hashValue == item.hashValue })
                        {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.accentColor)
                        } else {
                            Image(systemName: "circle")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                }
            }
        }

        Divider()

        Section {
            MultiSelectListRowMenu(
                L10n.genres,
                subtitle: selectedGenresSubtitle,
                items: viewModel.allFilters.genres.map(\.asAnyItemFilter),
                selectedItems: Binding(
                    get: { viewModel.currentFilters.genres.map(\.asAnyItemFilter) },
                    set: { newGenres in
                        let genreValues = newGenres.compactMap { filter in
                            ItemGenre(stringLiteral: filter.value)
                        }
                        viewModel.send(.update(.genres, genreValues.map(\.asAnyItemFilter)))
                    }
                )
            )
        }

        Section {
            MultiSelectListRowMenu(
                L10n.years,
                subtitle: selectedYearsSubtitle,
                items: viewModel.allFilters.years.map(\.asAnyItemFilter),
                selectedItems: Binding(
                    get: { viewModel.currentFilters.years.map(\.asAnyItemFilter) },
                    set: { newYears in
                        let yearValues = newYears.compactMap { filter in
                            ItemYear(from: filter)
                        }
                        viewModel.send(.update(.years, yearValues.map(\.asAnyItemFilter)))
                    }
                )
            )
        }
    }
}

// MARK: - MultiSelectListRowMenu

struct MultiSelectListRowMenu<Item: Hashable>: View {

    // MARK: - Focus State

    @FocusState
    private var isFocused: Bool

    // MARK: - Properties

    private let title: String
    private let subtitle: String
    private let items: [Item]
    private let selectedItems: Binding<[Item]>
    private let displayTitle: (Item) -> String

    // MARK: - Body

    var body: some View {
        Menu {
            ForEach(items, id: \.hashValue) { item in
                Button(action: {
                    toggleItem(item)
                }) {
                    HStack {
                        Text(displayTitle(item))
                        Spacer()
                        if selectedItems.wrappedValue.contains(item) {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack {
                Text(title)
                    .foregroundStyle(isFocused ? .black : .white)
                    .padding(.leading, 4)

                Spacer()

                Text(subtitle)
                    .foregroundStyle(isFocused ? .black : .white)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.body.weight(.regular))
                    .foregroundStyle(isFocused ? .black : .white)
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .scaleEffect(isFocused ? 1.04 : 1.0)
            .animation(.easeInOut(duration: 0.125), value: isFocused)
        }
        .listRowInsets(.zero)
        .focused($isFocused)
    }

    // MARK: - Helper Methods

    private func toggleItem(_ item: Item) {
        var currentSelection = selectedItems.wrappedValue
        if currentSelection.contains(item) {
            currentSelection.removeAll { $0.hashValue == item.hashValue }
        } else {
            currentSelection.append(item)
        }
        selectedItems.wrappedValue = currentSelection
    }
}

// MARK: - MultiSelectListRowMenu Initializers

extension MultiSelectListRowMenu where Item: Displayable {
    init(
        _ title: String,
        subtitle: String,
        items: [Item],
        selectedItems: Binding<[Item]>
    ) {
        self.title = title
        self.subtitle = subtitle
        self.items = items
        self.selectedItems = selectedItems
        self.displayTitle = { $0.displayTitle }
    }
}
