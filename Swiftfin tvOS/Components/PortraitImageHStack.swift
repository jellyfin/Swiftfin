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

struct PortraitImageHStack<Item: PortraitPoster, LastView: View>: View {

    private let loading: Bool
    private let title: String
    private let items: [Item]
    private let selectedAction: (Item) -> Void
    private let lastView: () -> LastView

    init(
        loading: Bool = false,
        title: String,
        items: [Item],
        @ViewBuilder lastView: @escaping () -> LastView,
        selectedAction: @escaping (Item) -> Void
    ) {
        self.loading = loading
        self.title = title
        self.items = items
        self.lastView = lastView
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
                        ForEach(0..<10) { _ in
                            PortraitButton(item: BaseItemDto.placeHolder,
                                           selectedAction: { _ in })
                            .redacted(reason: .placeholder)
                        }
                    } else if items.isEmpty {
                        PortraitButton(item: BaseItemDto.noResults,
                                       selectedAction: { _ in })
                    } else {
                        ForEach(items, id: \.title + \.subtitle) { item in
                            PortraitButton(item: item) { item in
                                selectedAction(item)
                            }
                        }
                    }

                    lastView()
                }
                .padding(.horizontal, 50)
                .padding2(.vertical)
            }
        }
    }
}

extension PortraitImageHStack where LastView == EmptyView {
    init(
        loading: Bool = false,
        title: String,
        items: [ItemType],
        selectedAction: @escaping (ItemType) -> Void
    ) {
        self.loading = loading
        self.title = title
        self.items = items
        self.lastView = { EmptyView() }
        self.selectedAction = selectedAction
    }
}
