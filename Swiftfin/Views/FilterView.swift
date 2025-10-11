//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

// TODO: multiple filter types?
//       - for sort order and sort by combined
struct FilterView: View {

    @Binding
    private var selection: [AnyItemFilter]

    @Router
    private var router

    @ObservedObject
    private var viewModel: FilterViewModel

    private let type: ItemFilterType

    private var filterSource: [AnyItemFilter] {
        viewModel.allFilters[keyPath: type.collectionAnyKeyPath]
    }

    @ViewBuilder
    private var contentView: some View {
        if filterSource.isEmpty {
            Text(L10n.none)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        } else {
            SelectorView(
                selection: $selection,
                sources: filterSource,
                type: type.selectorType
            )
        }
    }

    var body: some View {
        contentView
            .navigationTitle(type.displayTitle)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarCloseButton {
                router.dismiss()
            }
            .topBarTrailing {
                Button(L10n.reset) {
                    viewModel.reset(filterType: type)
                }
                .environment(
                    \.isEnabled,
                    viewModel.isFilterSelected(type: type)
                )
            }
    }
}

extension FilterView {

    init(
        viewModel: FilterViewModel,
        type: ItemFilterType
    ) {

        let selectionBinding: Binding<[AnyItemFilter]> = Binding {
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
