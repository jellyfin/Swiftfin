//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct FilterMenu: View {

    @ObservedObject
    var viewModel: FilterViewModel

    @FocusState
    private var isFocused: Bool

    var filterTypes: [ItemFilterType]

    var body: some View {
        Menu {
            if viewModel.currentFilters.hasFilters {
                Button(L10n.reset, role: .destructive) {
                    viewModel.currentFilters = .default
                }
                .foregroundColor(.primary)
                Divider()
            }
            ForEach(filterTypes, id: \.self) { type in
                createFilterMenu(for: type)
            }
        } label: {
            ZStack {
                Circle()
                    .fill(isFocused ? Color.lightGray : Color.clear)
                    .frame(width: 40, height: 40)
                Image(
                    systemName: isFocused || !viewModel.currentFilters
                        .hasFilters ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill"
                )
                .foregroundColor(isFocused ? .black : (viewModel.currentFilters.hasFilters ? Color.jellyfinPurple : Color.white))
                .shadow(color: isFocused ? .clear : .black, radius: 2, x: 0, y: 2)
            }
            .frame(width: 35, height: 35)
        }
        .buttonStyle(.borderless)
        .focused($isFocused)
        .padding(25)
    }

    @ViewBuilder
    private func createFilterMenu(for type: ItemFilterType) -> some View {
        Menu {
            ForEach(viewModel.allFilters[keyPath: type.collectionAnyKeyPath], id: \.self) { filter in
                Button {
                    handleFilterSelection(filter, for: type)
                } label: {
                    HStack {
                        Text(filter.displayTitle)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Spacer()

                        if viewModel.currentFilters[keyPath: type.collectionAnyKeyPath].contains(filter) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            }
        } label: {
            Text(type.displayTitle)
                .foregroundColor(.primary)
        }
    }

    private func handleFilterSelection(_ filter: AnyItemFilter, for type: ItemFilterType) {
        var currentFilters = viewModel.currentFilters[keyPath: type.collectionAnyKeyPath]

        switch type.selectorType {
        case .single:
            currentFilters = [filter]
        case .multi:
            if let index = currentFilters.firstIndex(where: { $0.displayTitle == filter.displayTitle }) {
                currentFilters.remove(at: index)
            } else {
                currentFilters.append(filter)
            }
        }

        updateFilters(currentFilters, for: type)
    }

    private func updateFilters(_ filters: [AnyItemFilter], for type: ItemFilterType) {
        switch type {
        case .genres:
            viewModel.currentFilters.genres = filters.map(ItemGenre.init)
        case .letter:
            viewModel.currentFilters.letter = filters.map(ItemLetter.init)
        case .sortBy:
            viewModel.currentFilters.sortBy = filters.map(ItemSortBy.init)
        case .sortOrder:
            viewModel.currentFilters.sortOrder = filters.map(ItemSortOrder.init)
        case .tags:
            viewModel.currentFilters.tags = filters.map(ItemTag.init)
        case .traits:
            viewModel.currentFilters.traits = filters.map(ItemTrait.init)
        case .years:
            viewModel.currentFilters.years = filters.map(ItemYear.init)
        }
    }
}
