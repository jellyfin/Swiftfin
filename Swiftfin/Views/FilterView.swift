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

    // MARK: - Body

    var body: some View {
        contentView
            .navigationTitle(type.displayTitle)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarCloseButton {
                router.dismiss()
            }
            .topBarTrailing {
                Button(L10n.reset) {
                    viewModel.send(.reset(type))
                }
                .environment(
                    \.isEnabled,
                    viewModel.isFilterSelected(type: type)
                )
            }
    }

    // MARK: - Filter Content

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
}

extension FilterView {

    init(
        viewModel: FilterViewModel,
        type: ItemFilterType
    ) {

        let selectionBinding: Binding<[AnyItemFilter]> = Binding {
            viewModel.currentFilters[keyPath: type.collectionAnyKeyPath]
        } set: { newValue in
            viewModel.send(.update(type, newValue))
        }

        self.init(
            selection: selectionBinding,
            viewModel: viewModel,
            type: type
        )
    }
}
