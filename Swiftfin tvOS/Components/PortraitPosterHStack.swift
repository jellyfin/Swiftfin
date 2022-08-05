//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI
import SwiftUICollection
import TVUIKit

struct PortraitPosterHStack<Item: PortraitPoster, TrailingContent: View>: View {

    private let loading: Bool
    private let title: String
    private let items: [Item]
    private let selectedAction: (Item) -> Void
    private let trailingContent: () -> TrailingContent

    init(
        loading: Bool = false,
        title: String,
        items: [Item],
        @ViewBuilder trailingContent: @escaping () -> TrailingContent,
        selectedAction: @escaping (Item) -> Void
    ) {
        self.loading = loading
        self.title = title
        self.items = items
        self.trailingContent = trailingContent
        self.selectedAction = selectedAction
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.leading, 50)

            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 0) {
                    if loading {
                        ForEach(0 ..< 10) { _ in
                            PortraitButton(
                                item: BaseItemDto.placeHolder,
                                selectedAction: { _ in }
                            )
                            .redacted(reason: .placeholder)
                        }
                    } else if items.isEmpty {
                        PortraitButton(
                            item: BaseItemDto.noResults,
                            selectedAction: { _ in }
                        )
                    } else {
                        ForEach(items, id: \.hashValue) { item in
                            PortraitButton(item: item) { item in
                                selectedAction(item)
                            }
                        }
                    }

                    trailingContent()
                }
                .padding(.horizontal, 50)
                .padding2(.vertical)
            }
        }
    }
}

extension PortraitPosterHStack where TrailingContent == EmptyView {
    init(
        loading: Bool = false,
        title: String,
        items: [Item],
        selectedAction: @escaping (Item) -> Void
    ) {
        self.loading = loading
        self.title = title
        self.items = items
        self.trailingContent = { EmptyView() }
        self.selectedAction = selectedAction
    }
}
