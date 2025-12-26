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

    @Router
    private var router

    @ObservedObject
    private var viewModel: FilterViewModel

    private let types: [ItemFilterType]

    private var title: String {
        if types.count > 1 {
            types.map(\.displayTitle).joined(separator: " & ")
        } else {
            types.first?.displayTitle ?? L10n.unknown
        }
    }

    init(
        viewModel: FilterViewModel,
        types: [ItemFilterType]
    ) {
        self.viewModel = viewModel
        self.types = types
    }

    var body: some View {
        Form(systemImage: types.first?.systemImage ?? "line.3.horizontal.decrease") {
            ForEach(types) { type in
                selectorView(for: type)
            }
        }
        .navigationTitle(title)
        .topBarTrailing {
            Button(L10n.reset) {
                for type in types {
                    viewModel.send(.reset(type))
                }
            }
            .environment(
                \.isEnabled,
                types.contains {
                    viewModel.isFilterSelected(type: $0)
                }
            )
        }
        .navigationBarCloseButton {
            router.dismiss()
        }
    }

    @ViewBuilder
    private func selectorView(for type: ItemFilterType) -> some View {

        let source = viewModel.allFilters[keyPath: type.collectionAnyKeyPath]

        if source.isNotEmpty {
            Section {
                SelectorView(
                    selection: Binding<[AnyItemFilter]>(
                        get: {
                            viewModel.currentFilters[keyPath: type.collectionAnyKeyPath]
                        },
                        set: { newValue in
                            viewModel.send(.update(type, newValue))
                        }
                    ),
                    sources: source,
                    type: type.selectorType
                )
            } header: {
                if types.count > 1 {
                    Text(type.displayTitle)
                }
            }
        } else {
            Text(L10n.none)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
}
