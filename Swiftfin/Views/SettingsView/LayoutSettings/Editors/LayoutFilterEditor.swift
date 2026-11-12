//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct LayoutFilterEditor: View {

    @Binding
    var filters: ItemFilterCollection

    @StoredValue(.User.savedFilters)
    private var savedFilters

    private let library: LibraryReference?

    @Router
    private var router

    init(filters: Binding<ItemFilterCollection>, library: LibraryReference? = nil) {
        _filters = filters
        self.library = library
    }

    private var savableFilters: ItemFilterCollection {
        filters
            .mutating(\.itemTypes, with: [])
            .mutating(\.query, with: nil)
    }

    private var selectedSavedFilter: StoredItemFilter? {
        savedFilters.first { $0.filters == savableFilters }
    }

    private func applyFilters(_ savedFilters: ItemFilterCollection) {
        filters = savedFilters
            .mutating(\.itemTypes, with: filters.itemTypes)
            .mutating(\.query, with: filters.query)
    }

    private var sortBy: Binding<ItemSortBy> {
        Binding {
            filters.sortBy.first ?? .sortName
        } set: {
            filters.sortBy = [$0]
        }
    }

    private var sortOrder: Binding<ItemSortOrder> {
        Binding {
            filters.sortOrder.first ?? .ascending
        } set: {
            filters.sortOrder = [$0]
        }
    }

    private func chooseGenres() {
        router.route(to: NavigationRoute(id: "layout-genres", style: .sheet) {
            LayoutGenrePickerView(selection: $filters.genres, library: library, itemTypes: filters.itemTypes)
        })
    }

    private func routeToItemTypes() {
        router.route(
            to: NavigationRoute(id: "layout-item-types") {
                SelectorView(
                    selection: $filters.itemTypes,
                    sources: LayoutItemTypes.all,
                    type: .multi
                )
                .navigationTitle(L10n.type)
            }
        )
    }

    private func routeToTraits() {
        router.route(
            to: NavigationRoute(id: "layout-traits") {
                SelectorView(
                    selection: $filters.traits,
                    sources: ItemTrait.supportedCases,
                    type: .multi
                )
                .navigationTitle(L10n.filters)
            }
        )
    }

    @ContentBuilder
    var body: some View {
        Section {
            Menu {
                ForEach(savedFilters) { savedFilter in
                    Button {
                        applyFilters(savedFilter.filters)
                    } label: {
                        if selectedSavedFilter?.id == savedFilter.id {
                            Label(savedFilter.name, systemImage: "checkmark")
                        } else {
                            Text(savedFilter.name)
                        }
                    }
                }
            } label: {
                LabeledContent(L10n.savedFilters) {
                    Text(selectedSavedFilter?.name ?? (savableFilters == .default ? L10n.none : L10n.custom))
                        .lineLimit(1)
                }
            }
            .disabled(savedFilters.isEmpty)

            TextField(
                L10n.search,
                value: $filters.query,
                format: .nilIfEmptyString
            )
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            ChevronButton(L10n.genres, action: chooseGenres) {
                Text(filters.genres.isEmpty ? L10n.all : filters.genres.map(\.displayTitle).joined(separator: ", "))
                    .lineLimit(1)
            }

            ChevronButton(L10n.type, action: routeToItemTypes) {
                Text(filters.itemTypes.isEmpty ? L10n.all : "\(filters.itemTypes.count)")
            }

            ChevronButton(L10n.filters, action: routeToTraits) {
                Text(filters.traits.isEmpty ? L10n.all : "\(filters.traits.count)")
            }

            Picker(L10n.sort, selection: sortBy) {
                ForEach(ItemSortBy.supportedCases, id: \.self) { sort in
                    Text(sort.displayTitle)
                        .tag(sort)
                }
            }

            Picker(L10n.order, selection: sortOrder) {
                ForEach(ItemSortOrder.allCases, id: \.self) { order in
                    Text(order.displayTitle)
                        .tag(order)
                }
            }

            Button(L10n.reset) {
                applyFilters(.default)
            }
            .disabled(savableFilters == .default)
        } header: {
            Text(L10n.filters)
        }
    }
}
