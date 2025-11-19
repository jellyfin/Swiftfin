//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct FilterView: PlatformView {

    @Router
    private var router

    @ObservedObject
    private var viewModel: FilterViewModel

    private let types: [ItemFilterType]

    private var isComposite: Bool {
        types.count > 1
    }

    private var title: String {
        if isComposite {
            types.map(\.displayTitle).joined(separator: " & ")
        } else {
            types.first?.displayTitle ?? L10n.unknown
        }
    }

    #if os(tvOS)
    private var systemImage: String {
        types.first?.systemImage ?? "line.3.horizontal.decrease"
    }
    #endif

    init(
        viewModel: FilterViewModel,
        types: [ItemFilterType]
    ) {
        self.viewModel = viewModel
        self.types = types
    }

    var iOSView: some View {
        Form {
            ForEach(types) { type in
                selectorView(for: type)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(title)
        .navigationBarCloseButton {
            router.dismiss()
        }
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
    }

    var tvOSView: some View {
        #if os(tvOS)
        SplitFormWindowView()
            .descriptionView {
                Image(systemName: systemImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 400)
            }
            .contentView {
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
        #endif
    }

    @ViewBuilder
    private func selectorView(for type: ItemFilterType) -> some View {

        let source = filterSource(type)

        let typeSelection = Binding<[AnyItemFilter]>(
            get: {
                viewModel.currentFilters[keyPath: type.collectionAnyKeyPath]
            },
            set: { newValue in
                viewModel.send(.update(type, newValue))
            }
        )

        if source.isEmpty {
            Text(L10n.none)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        } else {
            Section {
                SelectorView(
                    selection: typeSelection,
                    sources: source,
                    type: type.selectorType
                )
            } header: {
                if isComposite {
                    Text(type.displayTitle)
                }
            }
        }
    }

    private func filterSource(_ type: ItemFilterType) -> [AnyItemFilter] {
        viewModel.allFilters[keyPath: type.collectionAnyKeyPath]
    }
}
