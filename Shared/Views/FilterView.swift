//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct FilterView: View {

    @Router
    private var router

    @ObservedObject
    private var viewModel: FilterViewModel

    private let types: [ItemFilterType]

    init(
        viewModel: FilterViewModel,
        type: ItemFilterType
    ) {
        self.viewModel = viewModel
        self.types = [type]
    }

    init(
        viewModel: FilterViewModel,
        types: [ItemFilterType]
    ) {
        self.viewModel = viewModel
        self.types = types
    }

    @ViewBuilder
    private func section(for type: ItemFilterType) -> some View {
        ForEach(type.group, id: \.displayTitle) { group in
            let source = viewModel.allFilters[keyPath: group.keyPath]

            let selectionBinding: Binding<[AnyItemFilter]> = Binding {
                viewModel.currentFilters[keyPath: group.keyPath]
            } set: { newValue in
                group.setter(newValue, viewModel)
            }

            Section(group.displayTitle) {
                if source.isEmpty {
                    Text(L10n.none)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else {
                    SelectorView(
                        selection: selectionBinding,
                        sources: source,
                        type: group.selectorType
                    )
                }
            }
        }
    }

    var body: some View {
        Form(systemImage: "line.3.horizontal.decrease") {
            ForEach(types, id: \.self) { type in
                section(for: type)
            }
        }
        .backport
        .toolbarTitleDisplayMode(.inline)
        .navigationBarCloseButton {
            router.dismiss()
        }
        .topBarTrailing {
            Button(L10n.reset) {
                for type in types {
                    viewModel.reset(filterType: type)
                }
            }
            .enabled(types.contains { viewModel.isFilterSelected(type: $0) })
        }
    }
}
