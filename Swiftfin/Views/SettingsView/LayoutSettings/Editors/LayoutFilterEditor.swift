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

    private let library: ItemReference?

    @Router
    private var router

    init(filters: Binding<ItemFilterCollection>, library: ItemReference? = nil) {
        _filters = filters
        self.library = library
    }

    private func applyFilters(_ savedFilters: ItemFilterCollection) {
        filters = savedFilters
            .mutating(\.itemTypes, with: filters.itemTypes)
            .mutating(\.query, with: filters.query)
    }

    private func chooseSavedFilters() {
        router.route(to: NavigationRoute(id: "layout-saved-filters") {
            SavedFiltersView(onApply: applyFilters)
        })
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
        router.route(to: NavigationRoute(id: "layout-genres") {
            LayoutGenrePickerView(selection: $filters.genres, library: library, itemTypes: filters.itemTypes)
        })
    }

    private func routeToItemTypes() {
        router.route(
            to: NavigationRoute(id: "layout-item-types") {
                SelectorView(
                    selection: $filters.itemTypes,
                    sources: BaseItemKind.supportedCases,
                    type: .multi
                )
                .navigationTitle(L10n.type)
                .toolbarTitleDisplayMode(.inline)
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
                .toolbarTitleDisplayMode(.inline)
            }
        )
    }

    @ContentBuilder
    var body: some View {
        Section {
            Button(L10n.savedFilters, action: chooseSavedFilters)
                .disabled(savedFilters.isEmpty)
        }

        Section {
            SearchFilterRow(query: $filters.query)

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

            Picker(L10n.sort, selection: sortBy, onlySupported: true)
            Picker(L10n.order, selection: sortOrder)
        } header: {
            HStack {
                Text(L10n.filters)

                Spacer()

                Button(L10n.reset) {
                    applyFilters(.default)
                }
                .disabled(filters == ItemFilterCollection(itemTypes: filters.itemTypes, query: filters.query))
            }
        }
    }
}
