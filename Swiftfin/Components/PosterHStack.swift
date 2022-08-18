//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct PosterHStack<Item: Poster, Content: View, ImageOverlay: View, ContextMenu: View, TrailingContent: View>: View {

    private let title: String
    private let type: PosterType
    private let items: [Item]
    private let itemScale: CGFloat
    private let content: (Item) -> Content
    private let imageOverlay: (Item) -> ImageOverlay
    private let contextMenu: (Item) -> ContextMenu
    private let trailingContent: () -> TrailingContent
    private let onSelect: (Item) -> Void

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
                            .imageOverlay(imageOverlay)
                            .contextMenu(contextMenu)
                            .onSelect(onSelect)
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
    @ViewBuilder
    func scaleItems(_ scale: CGFloat) -> PosterHStack {
        PosterHStack(
            title: title,
            type: type,
            items: items,
            itemScale: scale,
            content: content,
            imageOverlay: imageOverlay,
            contextMenu: contextMenu,
            trailingContent: trailingContent,
            onSelect: onSelect
        )
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

    @ViewBuilder
    func onSelect(_ onSelect: @escaping (Item) -> Void) -> PosterHStack {
        PosterHStack(
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
}
