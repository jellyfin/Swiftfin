//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

/// `TabView` acts weird with horizontal stacks
struct SupplementTabView<Item: Identifiable, Content: View>: View {

    let items: [Item]
    let selection: Item.ID?

    @ViewBuilder
    let content: (Item) -> Content

    var body: some View {
        ZStack {
            ForEach(items) { item in
                let isSelected = item.id == selection

                content(item)
                    .opacity(isSelected ? 1 : 0)
                    .disabled(!isSelected)
                    .allowsHitTesting(isSelected)
                    .accessibilityHidden(!isSelected)
            }
        }
        .animation(.linear(duration: 0.2), value: selection)
    }
}
