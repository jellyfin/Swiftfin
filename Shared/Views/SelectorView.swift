//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

// TODO: Implement different behavior types, where selected/unselected
//       items can appear in different sections
struct SelectorView<Item: Displayable & Identifiable>: View {

    @Default(.accentColor)
    private var accentColor

    @Binding
    private var selectedItems: [Item]

    private let allItems: [Item]
    private var label: (Item) -> any View
    private let type: SelectorType

    var body: some View {
        List {
            ForEach(allItems) { item in
                Button {
                    switch type {
                    case .single:
                        handleSingleSelect(with: item)
                    case .multi:
                        handleMultiSelect(with: item)
                    }
                } label: {
                    HStack {
                        label(item).eraseToAnyView()

                        Spacer()

                        if selectedItems.contains { $0.id == item.id } {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(accentColor)
                        } else {
                            Image(systemName: "circle")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }

    private func handleSingleSelect(with item: Item) {
        selectedItems = [item]
    }

    private func handleMultiSelect(with item: Item) {
        if selectedItems.contains(where: { $0.id == item.id }) {
            selectedItems.removeAll(where: { $0.id == item.id })
        } else {
            selectedItems.append(item)
        }
    }
}

extension SelectorView {

    init(type: SelectorType, allItems: [Item], selectedItems: Binding<[Item]>) {
        self.init(
            selectedItems: selectedItems,
            allItems: allItems,
            label: { Text($0.displayTitle).foregroundColor(.primary) },
            type: type
        )
    }

    func label(@ViewBuilder _ content: @escaping (Item) -> any View) -> Self {
        copy(modifying: \.label, with: content)
    }
}
