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

    // MARK: - Binded Variable

    @Binding
    private var selection: [AnyItemFilter]

    // MARK: - Environment & Observed Objects

    @Router
    private var router

    @ObservedObject
    private var viewModel: FilterViewModel

    // MARK: - Filter Type

    private let type: ItemFilterType

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

    // MARK: - Icon Helper

    private func iconForFilterType(_ type: ItemFilterType) -> String {
        switch type {
        case .sortBy:
            return "arrow.up.arrow.down"
        case .traits:
            return "line.3.horizontal.decrease"
        default:
            return "circle"
        }
    }

    // MARK: - Body

    var body: some View {
        SplitFormWindowView()
            .descriptionView {
                Image(systemName: iconForFilterType(type))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 400)
            }
            .contentView {
                contentView
            }
            .navigationTitle(type.displayTitle)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L10n.close) {
                        router.dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.reset) {
                        if type == .sortBy {
                            // Reset both sortBy and sortOrder
                            viewModel.send(.reset(.sortBy))
                            viewModel.send(.reset(.sortOrder))
                        } else if type == .traits {
                            // Reset both traits and genres
                            viewModel.send(.reset(.traits))
                            viewModel.send(.reset(.genres))
                        } else {
                            viewModel.send(.reset(type))
                        }
                    }
                    .disabled(!viewModel.isFilterSelected(type: type) &&
                        !(type == .sortBy && viewModel.isFilterSelected(type: .sortOrder)) &&
                        !(type == .traits && viewModel.isFilterSelected(type: .genres)))
                }
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
        } else if filterSource.isEmpty {
            Section {
                Text(L10n.none)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        } else {
            Section {
                ForEach(filterSource, id: \.hashValue) { item in
                    Button(action: {
                        if type.selectorType == .single {
                            viewModel.send(.update(type, [item]))
                        } else {
                            // Multi-select: toggle item
                            let currentSelection = viewModel.currentFilters[keyPath: type.collectionAnyKeyPath]
                            if currentSelection.contains(where: { $0.hashValue == item.hashValue }) {
                                // Remove item
                                let newSelection = currentSelection.filter { $0.hashValue != item.hashValue }
                                viewModel.send(.update(type, newSelection))
                            } else {
                                // Add item
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
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Sort Content View

    @ViewBuilder
    private var sortContentView: some View {
        Section(L10n.sort) {
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
                .buttonStyle(.plain)
            }
        }

        Section(L10n.order) {
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
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Filters Content View

    @ViewBuilder
    private var filtersContentView: some View {
        Section(L10n.filters) {
            ForEach(filterSource, id: \.hashValue) { item in
                Button(action: {
                    if type.selectorType == .single {
                        viewModel.send(.update(type, [item]))
                    } else {
                        // Multi-select: toggle item
                        let currentSelection = viewModel.currentFilters[keyPath: type.collectionAnyKeyPath]
                        if currentSelection.contains(where: { $0.hashValue == item.hashValue }) {
                            // Remove item
                            let newSelection = currentSelection.filter { $0.hashValue != item.hashValue }
                            viewModel.send(.update(type, newSelection))
                        } else {
                            // Add item
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
                .buttonStyle(.plain)
            }
        }

        Section(L10n.genres) {
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
    }
}

extension FilterView {

    init(
        viewModel: FilterViewModel,
        type: ItemFilterType
    ) {
        self.viewModel = viewModel
        self.type = type
        self._selection = Binding(
            get: { viewModel.currentFilters[keyPath: type.collectionAnyKeyPath] },
            set: { newValue in
                viewModel.send(.update(type, newValue))
            }
        )
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
                                .foregroundColor(.jellyfinPurple)
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
                    .foregroundStyle(isFocused ? .black : .secondary)
                    .brightness(isFocused ? 0.4 : 0)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.body.weight(.regular))
                    .foregroundStyle(isFocused ? .black : .secondary)
                    .brightness(isFocused ? 0.4 : 0)
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isFocused ? Color.white : Color.clear)
            )
            .scaleEffect(isFocused ? 1.04 : 1.0)
            .animation(.easeInOut(duration: 0.125), value: isFocused)
        }
        .menuStyle(.borderlessButton)
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
