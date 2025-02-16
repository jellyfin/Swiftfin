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
                viewModel.send(.reset(type))
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
            viewModel.send(.update(type, newValue))
        }

        self.init(
            selection: selectionBinding,
            viewModel: viewModel,
            type: type
        )
    }
}
