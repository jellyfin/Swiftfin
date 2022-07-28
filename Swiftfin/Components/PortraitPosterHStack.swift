//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct PortraitPosterHStack<Item: PortraitPoster, TrailingContent: View>: View {

    private let title: String
    private let items: [Item]
    private let itemWidth: CGFloat
    private let trailingContent: () -> TrailingContent
    private let selectedAction: (Item) -> Void

    init(
        title: String,
        items: [Item],
        itemWidth: CGFloat = 110,
        @ViewBuilder trailingContent: @escaping () -> TrailingContent,
        selectedAction: @escaping (Item) -> Void
    ) {
        self.title = title
        self.items = items
        self.itemWidth = itemWidth
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
                        PortraitPosterButton(
                            item: item,
                            maxWidth: itemWidth,
                            horizontalAlignment: .leading
                        ) { item in
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

extension PortraitPosterHStack where TrailingContent == EmptyView {
    init(
        title: String,
        items: [Item],
        itemWidth: CGFloat = 110,
        selectedAction: @escaping (Item) -> Void
    ) {
        self.title = title
        self.items = items
        self.itemWidth = itemWidth
        self.trailingContent = { EmptyView() }
        self.selectedAction = selectedAction
    }
}
