//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct InlineEnumToggle<ItemType: CaseIterable & Displayable & Hashable>: View {

    @Binding
    private var selection: ItemType

    private let title: String

    var body: some View {
        Button {
            guard let currentSelectionIndex = ItemType.allCases.firstIndex(of: selection) else { return }

            if ItemType.allCases.index(currentSelectionIndex, offsetBy: 1) == ItemType.allCases.endIndex {
                selection = ItemType.allCases[ItemType.allCases.startIndex]
            } else {
                selection = ItemType.allCases[ItemType.allCases.index(currentSelectionIndex, offsetBy: 1)]
            }
        } label: {
            HStack {
                Text(title)

                Spacer()

                Text(selection.displayTitle)
                    .foregroundColor(.secondary)
            }
        }
    }
}

extension InlineEnumToggle {

    init(title: String, selection: Binding<ItemType>) {
        self.init(
            selection: selection,
            title: title
        )
    }
}
