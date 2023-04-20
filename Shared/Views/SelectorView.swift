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
    private var selection: [Item]

    private let allItems: [Item]
    private var label: (Item) -> any View
    private let type: SelectorType

    var body: some View {
        List(allItems) { item in
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

                    if selection.contains { $0.id == item.id } {
                        Image(systemName: "checkmark.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                            .accentSymbolRendering()
                    }
                }
            }
        }
    }

    private func handleSingleSelect(with item: Item) {
        selection = [item]
    }

    private func handleMultiSelect(with item: Item) {
        if selection.contains(where: { $0.id == item.id }) {
            selection.removeAll(where: { $0.id == item.id })
        } else {
            selection.append(item)
        }
    }
}

extension SelectorView {

    init(selection: Binding<[Item]>, allItems: [Item], type: SelectorType) {
        self.init(
            selection: selection,
            allItems: allItems,
            label: { Text($0.displayTitle).foregroundColor(.primary) },
            type: type
        )
    }

    init(selection: Binding<Item>, allItems: [Item]) {
        self.init(
            selection: .init(get: { [selection.wrappedValue] }, set: { selection.wrappedValue = $0[0] }),
            allItems: allItems,
            label: { Text($0.displayTitle).foregroundColor(.primary) },
            type: .single
        )
    }

    func label(@ViewBuilder _ content: @escaping (Item) -> any View) -> Self {
        copy(modifying: \.label, with: content)
    }
}
