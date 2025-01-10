//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

// Note: Keep all of the ItemFilterCollection/ItemFilter/AnyItemFilter KeyPath wackiness in this file

// TODO: multiple filter types?
//       - for sort order and sort by combined
struct FilterView: View {

    @Binding
    private var selection: [AnyItemFilter]

    @EnvironmentObject
    private var router: FilterCoordinator.Router

    @ObservedObject
    private var viewModel: FilterViewModel

    private let type: ItemFilterType

    var body: some View {
        SelectorView(
            selection: $selection,
            sources: viewModel.allFilters[keyPath: type.collectionAnyKeyPath],
            type: type.selectorType
        )
        .navigationTitle(type.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarCloseButton {
            router.dismissCoordinator()
        }
        .topBarTrailing {
            Button(L10n.reset) {
                switch type {
                case .genres:
                    viewModel.currentFilters.genres = ItemFilterCollection.default.genres
                case .letter:
                    viewModel.currentFilters.letter = ItemFilterCollection.default.letter
                case .sortBy:
                    viewModel.currentFilters.sortBy = ItemFilterCollection.default.sortBy
                case .sortOrder:
                    viewModel.currentFilters.sortOrder = ItemFilterCollection.default.sortOrder
                case .tags:
                    viewModel.currentFilters.tags = ItemFilterCollection.default.tags
                case .traits:
                    viewModel.currentFilters.traits = ItemFilterCollection.default.traits
                case .years:
                    viewModel.currentFilters.years = ItemFilterCollection.default.years
                }
            }
            .environment(
                \.isEnabled,
                viewModel.currentFilters[keyPath: type.collectionAnyKeyPath] != ItemFilterCollection
                    .default[keyPath: type.collectionAnyKeyPath]
            )
        }
    }
}

extension FilterView {

    init(
        viewModel: FilterViewModel,
        type: ItemFilterType
    ) {

        let selectionBinding = Binding {
            viewModel.currentFilters[keyPath: type.collectionAnyKeyPath]
        } set: { newValue in
            switch type {
            case .genres:
                viewModel.currentFilters.genres = newValue.map(ItemGenre.init)
            case .letter:
                viewModel.currentFilters.letter = newValue.map(ItemLetter.init)
            case .sortBy:
                viewModel.currentFilters.sortBy = newValue.map(ItemSortBy.init)
            case .sortOrder:
                viewModel.currentFilters.sortOrder = newValue.map(ItemSortOrder.init)
            case .tags:
                viewModel.currentFilters.tags = newValue.map(ItemTag.init)
            case .traits:
                viewModel.currentFilters.traits = newValue.map(ItemTrait.init)
            case .years:
                viewModel.currentFilters.years = newValue.map(ItemYear.init)
            }
        }

        self.init(
            selection: selectionBinding,
            viewModel: viewModel,
            type: type
        )
    }
}
