//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct PosterHStack<Item: Poster>: View {

    private var title: String?
    private var type: PosterType
    private var items: [Item]
    private var itemScale: CGFloat
    private var content: (Item) -> any View
    private var imageOverlay: (Item) -> any View
    private var contextMenu: (Item) -> any View
    private var trailingContent: () -> any View
    private var onSelect: (Item) -> Void

    // See PosterButton for implementation reason
    private var focusedItem: Binding<Item?>?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            if let title = title {
                HStack {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .accessibility(addTraits: [.isHeader])
                        .padding(.leading, 50)

                    Spacer()
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 30) {
                    ForEach(items, id: \.hashValue) { item in
                        PosterButton(item: item, type: type)
                            .scaleItem(itemScale)
                            .content { content(item).eraseToAnyView() }
                            .imageOverlay { imageOverlay(item).eraseToAnyView() }
                            .contextMenu { contextMenu(item).eraseToAnyView() }
                            .onSelect { onSelect(item) }
                            .if(focusedItem != nil) { view in
                                view.onFocusChanged { isFocused in
                                    if isFocused { focusedItem?.wrappedValue = item }
                                }
                            }
                    }

                    trailingContent()
                        .eraseToAnyView()
                }
                .padding(50)
            }
        }
        .focusSection()
        .mask {
            VStack(spacing: 0) {
                Color.white

                LinearGradient(
                    stops: [
                        .init(color: .white, location: 0),
                        .init(color: .clear, location: 1),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 20)
            }
        }
    }
}

extension PosterHStack {

    init(
        title: String? = nil,
        type: PosterType,
        items: [Item]
    ) {
        self.init(
            title: title,
            type: type,
            items: items,
            itemScale: 1,
            content: { PosterButton.DefaultContentView(item: $0) },
            imageOverlay: { PosterButton.DefaultOverlay(item: $0) },
            contextMenu: { _ in EmptyView() },
            trailingContent: { EmptyView() },
            onSelect: { _ in },
            focusedItem: nil
        )
    }
}

extension PosterHStack {

    func scaleItems(_ scale: CGFloat) -> Self {
        copy(modifying: \.itemScale, with: scale)
    }

    func content(@ViewBuilder _ content: @escaping (Item) -> any View) -> Self {
        copy(modifying: \.content, with: content)
    }

    func imageOverlay(@ViewBuilder _ content: @escaping (Item) -> any View) -> Self {
        copy(modifying: \.imageOverlay, with: content)
    }

    func contextMenu(@ViewBuilder _ content: @escaping (Item) -> any View) -> Self {
        copy(modifying: \.contextMenu, with: content)
    }

    func trailing(@ViewBuilder _ content: @escaping () -> any View) -> Self {
        copy(modifying: \.trailingContent, with: content)
    }

    func onSelect(_ action: @escaping (Item) -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }

    func focusedItem(_ binding: Binding<Item?>) -> Self {
        copy(modifying: \.focusedItem, with: binding)
    }
}
