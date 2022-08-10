//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct LandscapePosterButton<Item: LandscapePoster>: View {
    
    @ScaledMetric(relativeTo: .largeTitle)
    private var scaledImageWidth = 200.0

    private let item: Item
    private let itemScale: CGFloat
    private let horizontalAlignment: HorizontalAlignment
    private let selectedAction: (Item) -> Void
    
    private var itemWidth: CGFloat {
        return scaledImageWidth * itemScale
    }

    init(
        item: Item,
        selectedAction: @escaping (Item) -> Void
    ) {
        self.init(
            item: item,
            itemScale: 1,
            horizontalAlignment: .leading,
            selectedAction: selectedAction
        )
    }

    private init(
        item: Item,
        itemScale: CGFloat,
        horizontalAlignment: HorizontalAlignment,
        selectedAction: @escaping (Item) -> Void
    ) {
        self.item = item
        self.itemScale = itemScale
        self.horizontalAlignment = horizontalAlignment
        self.selectedAction = selectedAction
    }

    var body: some View {
        Button {
            selectedAction(item)
        } label: {
            VStack(alignment: horizontalAlignment) {
                ImageView(item.landscapePosterImageSources(maxWidth: itemWidth))
                    .landscapePoster(width: itemWidth)

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
            .frame(width: itemWidth)
        }
        .posterShadow()
    }
}

extension LandscapePosterButton {
    @ViewBuilder
    func horizontalAlignment(_ alignment: HorizontalAlignment) -> LandscapePosterButton {
        LandscapePosterButton(item: item,
                              itemScale: itemScale,
                              horizontalAlignment: alignment,
                              selectedAction: selectedAction)
    }

    @ViewBuilder
    func scaleItem(_ scale: CGFloat) -> LandscapePosterButton {
        LandscapePosterButton(item: item,
                              itemScale: scale,
                              horizontalAlignment: horizontalAlignment,
                              selectedAction: selectedAction)
    }
}
