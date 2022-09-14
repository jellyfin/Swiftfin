//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import CollectionView
import SwiftUI

struct PosterHStack<Item: Poster, Content: View, ImageOverlay: View, ContextMenu: View, TrailingContent: View>: View {

    private var title: String
    private var type: PosterType
    private var items: [Item]
    private var itemScale: CGFloat
    private var content: (Item) -> Content
    private var imageOverlay: (Item) -> ImageOverlay
    private var contextMenu: (Item) -> ContextMenu
    private var trailingContent: () -> TrailingContent
    private var onSelect: (Item) -> Void

    private init(
        title: String,
        type: PosterType,
        items: [Item],
        itemScale: CGFloat,
        @ViewBuilder content: @escaping (Item) -> Content,
        @ViewBuilder imageOverlay: @escaping (Item) -> ImageOverlay,
        @ViewBuilder contextMenu: @escaping (Item) -> ContextMenu,
        @ViewBuilder trailingContent: @escaping () -> TrailingContent,
        onSelect: @escaping (Item) -> Void
    ) {
        self.title = title
        self.type = type
        self.items = items
        self.itemScale = itemScale
        self.content = content
        self.imageOverlay = imageOverlay
        self.contextMenu = contextMenu
        self.trailingContent = trailingContent
        self.onSelect = onSelect
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .accessibility(addTraits: [.isHeader])

                Spacer()

                trailingContent()
            }
            .padding(.horizontal)
            .if(UIDevice.isIPad) { view in
                view.padding(.horizontal)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 15) {
                    ForEach(items, id: \.hashValue) { item in
                        PosterButton(item: item, type: type)
                            .scaleItem(itemScale)
                            .content { content(item) }
                            .imageOverlay { imageOverlay(item) }
                            .contextMenu { contextMenu(item) }
                            .onSelect { onSelect(item) }
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

extension PosterHStack where Content == PosterButtonDefaultContentView<Item>,
    ImageOverlay == EmptyView,
    ContextMenu == EmptyView,
    TrailingContent == EmptyView
{
    init(
        title: String,
        type: PosterType,
        items: [Item]
    ) {
        self.init(
            title: title,
            type: type,
            items: items,
            itemScale: 1,
            content: { PosterButtonDefaultContentView(item: $0) },
            imageOverlay: { _ in EmptyView() },
            contextMenu: { _ in EmptyView() },
            trailingContent: { EmptyView() },
            onSelect: { _ in }
        )
    }
}

extension PosterHStack {

    func scaleItems(_ scale: CGFloat) -> Self {
        var copy = self
        copy.itemScale = scale
        return copy
    }

    @ViewBuilder
    func content<C: View>(@ViewBuilder _ content: @escaping (Item) -> C)
    -> PosterHStack<Item, C, ImageOverlay, ContextMenu, TrailingContent> {
        PosterHStack<Item, C, ImageOverlay, ContextMenu, TrailingContent>(
            title: title,
            type: type,
            items: items,
            itemScale: itemScale,
            content: content,
            imageOverlay: imageOverlay,
            contextMenu: contextMenu,
            trailingContent: trailingContent,
            onSelect: onSelect
        )
    }

    @ViewBuilder
    func imageOverlay<O: View>(@ViewBuilder _ imageOverlay: @escaping (Item) -> O)
    -> PosterHStack<Item, Content, O, ContextMenu, TrailingContent> {
        PosterHStack<Item, Content, O, ContextMenu, TrailingContent>(
            title: title,
            type: type,
            items: items,
            itemScale: itemScale,
            content: content,
            imageOverlay: imageOverlay,
            contextMenu: contextMenu,
            trailingContent: trailingContent,
            onSelect: onSelect
        )
    }

    @ViewBuilder
    func contextMenu<M: View>(@ViewBuilder _ contextMenu: @escaping (Item) -> M)
    -> PosterHStack<Item, Content, ImageOverlay, M, TrailingContent> {
        PosterHStack<Item, Content, ImageOverlay, M, TrailingContent>(
            title: title,
            type: type,
            items: items,
            itemScale: itemScale,
            content: content,
            imageOverlay: imageOverlay,
            contextMenu: contextMenu,
            trailingContent: trailingContent,
            onSelect: onSelect
        )
    }

    @ViewBuilder
    func trailing<T: View>(@ViewBuilder _ trailingContent: @escaping () -> T)
    -> PosterHStack<Item, Content, ImageOverlay, ContextMenu, T> {
        PosterHStack<Item, Content, ImageOverlay, ContextMenu, T>(
            title: title,
            type: type,
            items: items,
            itemScale: itemScale,
            content: content,
            imageOverlay: imageOverlay,
            contextMenu: contextMenu,
            trailingContent: trailingContent,
            onSelect: onSelect
        )
    }

    func onSelect(_ action: @escaping (Item) -> Void) -> Self {
        var copy = self
        copy.onSelect = action
        return copy
    }
}
