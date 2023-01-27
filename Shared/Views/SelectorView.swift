//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: Implement different behavior types, where selected/unselected
//       items appear in different sections
struct SelectorView<Item: Displayable>: View {

    private let allItems: [Item]
    @Binding
    private var selectedItems: [Item]
    private let type: SelectorType

    init(type: SelectorType, allItems: [Item], selectedItems: Binding<[Item]>) {
        self.type = type
        self.allItems = allItems
        self._selectedItems = selectedItems
    }

    var body: some View {
        List {
            ForEach(allItems, id: \.displayName) { item in
                Button {
                    switch type {
                    case .single:
                        handleSingleSelect(with: item)
                    case .multi:
                        handleMultiSelect(with: item)
                    }
                } label: {
                    HStack {
                        Text(item.displayName)
                            .foregroundColor(.primary)

                        Spacer()

                        if selectedItems.contains { $0.displayName == item.displayName } {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.jellyfinPurple)
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
        if selectedItems.contains(where: { $0.displayName == item.displayName }) {
            selectedItems.removeAll(where: { $0.displayName == item.displayName })
        } else {
            selectedItems.append(item)
        }
    }
}
