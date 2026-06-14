//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct PillHStack<Item: Displayable>: View {

    let title: String
    let items: [Item]
    let action: (Item) -> Void

    @Default(.isLiquidGlassEnabled)
    private var isLiquidGlassEnabled

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
                        let button = Button {
                            action(item)
                        } label: {
                            let text = Text(item.displayTitle)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            if isLiquidGlassEnabled, #available(iOS 26.0, *) {
                                text
                            } else {
                                text.background {
                                    Color.systemFill
                                        .cornerRadius(10)
                                }
                                .padding(10)
                            }
                        }
                        if isLiquidGlassEnabled, #available(iOS 26.0, *) {
                            button.buttonStyle(.glass).padding(.vertical(5))
                        } else {
                            button
                        }
                    }
                }
                .edgePadding(.horizontal)
            }
        }
    }
}
