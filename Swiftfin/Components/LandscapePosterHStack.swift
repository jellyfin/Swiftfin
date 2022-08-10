//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct LandscapePosterHStack<Item: LandscapePoster, TrailingContent: View>: View {

    private let title: String
    private let items: [Item]
    private let itemScale: CGFloat
    private let trailingContent: () -> TrailingContent
    private let selectedAction: (Item) -> Void

    init(
        title: String,
        items: [Item],
        @ViewBuilder trailingContent: @escaping () -> TrailingContent,
        selectedAction: @escaping (Item) -> Void
    ) {
        self.init(
            title: title,
            items: items,
            itemScale: 1,
            trailingContent: trailingContent,
            selectedAction: selectedAction
        )
    }

    private init(
        title: String,
        items: [Item],
        itemScale: CGFloat,
        @ViewBuilder trailingContent: @escaping () -> TrailingContent,
        selectedAction: @escaping (Item) -> Void
    ) {
        self.title = title
        self.items = items
        self.itemScale = itemScale
        self.trailingContent = trailingContent
        self.selectedAction = selectedAction
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .accessibility(addTraits: [.isHeader])
                    .padding(.leading)
                    .if(UIDevice.isIPad) { view in
                        view.padding(.leading)
                    }

                Spacer()

                trailingContent()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 15) {
                    ForEach(items, id: \.hashValue) { item in
                        LandscapePosterButton(item: item) { item in
                            selectedAction(item)
                        }
                    }
                }
                .padding(.horizontal)
                .if(UIDevice.isIPad) { view in
                    view.padding(.horizontal)
                }
            }
        }
    }
}

extension LandscapePosterHStack where TrailingContent == EmptyView {
    init(
        title: String,
        items: [Item],
        selectedAction: @escaping (Item) -> Void
    ) {
        self.init(
            title: title,
            items: items,
            itemScale: 1,
            trailingContent: { EmptyView() },
            selectedAction: selectedAction
        )
    }
}

extension LandscapePosterHStack {
    @ViewBuilder
    func scaleItems(_ scale: CGFloat) -> LandscapePosterHStack {
        LandscapePosterHStack(
            title: title,
            items: items,
            itemScale: scale,
            trailingContent: trailingContent,
            selectedAction: selectedAction
        )
    }
}
