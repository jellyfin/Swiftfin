//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct PortraitPosterButton<Item: PortraitPoster>: View {

    @Environment(\.colorScheme)
    private var colorScheme

    let item: Item
    let maxWidth: CGFloat
    let horizontalAlignment: HorizontalAlignment
    let selectedAction: (Item) -> Void

    init(
        item: Item,
        maxWidth: CGFloat = 110,
        horizontalAlignment: HorizontalAlignment = .leading,
        selectedAction: @escaping (Item) -> Void
    ) {
        self.item = item
        self.maxWidth = maxWidth
        self.horizontalAlignment = horizontalAlignment
        self.selectedAction = selectedAction
    }

    var body: some View {
        Button {
            selectedAction(item)
        } label: {
            VStack(alignment: horizontalAlignment) {
                ImageView(item.portraitPosterImageSource(maxWidth: maxWidth))
                    .failure {
                        InitialFailureView(item.title.initials)
                    }
                    .portraitPoster(width: maxWidth)
                    .accessibilityIgnoresInvertColors()

                if item.showTitle {
                    Text(item.title)
                        .font(.footnote)
                        .fontWeight(.regular)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                }

                if let description = item.subtitle {
                    Text(description)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            .frame(width: maxWidth)
        }
        .posterShadow()
    }
}
