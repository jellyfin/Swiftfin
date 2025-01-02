//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct PillHStack<Item: Displayable>: View {

    private var title: String
    private var items: [Item]
    private var onSelect: (Item) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .accessibility(addTraits: [.isHeader])
                .edgePadding(.leading)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(items, id: \.displayTitle) { item in
                        Button {
                            onSelect(item)
                        } label: {
                            Text(item.displayTitle)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .padding(10)
                                .background {
                                    Color.systemFill
                                        .cornerRadius(10)
                                }
                        }
                    }
                }
                .edgePadding(.horizontal)
            }
        }
    }
}

extension PillHStack {

    init(title: String, items: [Item]) {
        self.init(
            title: title,
            items: items,
            onSelect: { _ in }
        )
    }

    func onSelect(_ action: @escaping (Item) -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}
