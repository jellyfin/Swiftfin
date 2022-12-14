//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: Remove `Header` and `TrailingContent` and create `HeaderPosterHStack`

struct PosterHStack<Header: View, Item: Poster, Content: View, ImageOverlay: View, ContextMenu: View, TrailingContent: View>: View {

    private var header: () -> Header
    private var title: String?
    private var type: PosterType
    private var items: [PosterButtonType<Item>]
    private var singleImage: Bool
    private var itemScale: CGFloat
    private var content: (PosterButtonType<Item>) -> Content
    private var imageOverlay: (PosterButtonType<Item>) -> ImageOverlay
    private var contextMenu: (PosterButtonType<Item>) -> ContextMenu
    private var trailingContent: () -> TrailingContent
    private var onSelect: (Item) -> Void

    var body: some View {
        VStack(alignment: .leading) {

            HStack {
                if header() is EmptyView {
                    if let title = title {
                        Text(title)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .accessibility(addTraits: [.isHeader])
                    }
                } else {
                    header()
                }

                Spacer()

                trailingContent()
            }
            .padding(.horizontal)
            .if(UIDevice.isIPad) { view in
                view.padding(.horizontal)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 15) {
                    ForEach(items, id: \.id) { item in
                        PosterButton(
                            state: item,
                            type: type,
                            singleImage: singleImage
                        )
                        .scaleItem(itemScale)
                        .content { content($0) }
                        .imageOverlay { imageOverlay($0) }
                        .contextMenu { contextMenu($0) }
                        .onSelect {
                            if case let PosterButtonType.item(item) = item {
                                onSelect(item)
                            }
                        }
                        .transition(.slide)
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

extension PosterHStack where Header == EmptyView,
    Content == PosterButtonDefaultContentView<Item>,
    ImageOverlay == EmptyView,
    ContextMenu == EmptyView,
    TrailingContent == EmptyView
{

    // TODO: Remove
    init(
        title: String,
        type: PosterType,
        items: [Item],
        singleImage: Bool = false
    ) {
        self.init(
            header: { EmptyView() },
            title: title,
            type: type,
            items: items.map { PosterButtonType.item($0) },
            singleImage: singleImage,
            itemScale: 1,
            content: { PosterButtonDefaultContentView(state: $0) },
            imageOverlay: { _ in EmptyView() },
            contextMenu: { _ in EmptyView() },
            trailingContent: { EmptyView() },
            onSelect: { _ in }
        )
    }

    init(
        title: String,
        type: PosterType,
        items: [PosterButtonType<Item>],
        singleImage: Bool = false
    ) {
        self.init(
            header: { EmptyView() },
            title: title,
            type: type,
            items: items,
            singleImage: singleImage,
            itemScale: 1,
            content: { PosterButtonDefaultContentView(state: $0) },
            imageOverlay: { _ in EmptyView() },
            contextMenu: { _ in EmptyView() },
            trailingContent: { EmptyView() },
            onSelect: { _ in }
        )
    }

    init(
        type: PosterType,
        items: [PosterButtonType<Item>],
        singleImage: Bool = false
    ) {
        self.init(
            header: { EmptyView() },
            title: nil,
            type: type,
            items: items,
            singleImage: singleImage,
            itemScale: 1,
            content: { PosterButtonDefaultContentView(state: $0) },
            imageOverlay: { _ in EmptyView() },
            contextMenu: { _ in EmptyView() },
            trailingContent: { EmptyView() },
            onSelect: { _ in }
        )
    }
}

extension PosterHStack {

    func header<H: View>(@ViewBuilder _ header: @escaping () -> H)
    -> PosterHStack<H, Item, Content, ImageOverlay, ContextMenu, TrailingContent> {
        .init(
            header: header,
            title: title,
            type: type,
            items: items,
            singleImage: singleImage,
            itemScale: itemScale,
            content: content,
            imageOverlay: imageOverlay,
            contextMenu: contextMenu,
            trailingContent: trailingContent,
            onSelect: onSelect
        )
    }

    func scaleItems(_ scale: CGFloat) -> Self {
        copy(modifying: \.itemScale, with: scale)
    }

    func content<C: View>(@ViewBuilder _ content: @escaping (PosterButtonType<Item>) -> C)
    -> PosterHStack<Header, Item, C, ImageOverlay, ContextMenu, TrailingContent> {
        .init(
            header: header,
            title: title,
            type: type,
            items: items,
            singleImage: singleImage,
            itemScale: itemScale,
            content: content,
            imageOverlay: imageOverlay,
            contextMenu: contextMenu,
            trailingContent: trailingContent,
            onSelect: onSelect
        )
    }

    func imageOverlay<O: View>(@ViewBuilder _ imageOverlay: @escaping (PosterButtonType<Item>) -> O)
    -> PosterHStack<Header, Item, Content, O, ContextMenu, TrailingContent> {
        .init(
            header: header,
            title: title,
            type: type,
            items: items,
            singleImage: singleImage,
            itemScale: itemScale,
            content: content,
            imageOverlay: imageOverlay,
            contextMenu: contextMenu,
            trailingContent: trailingContent,
            onSelect: onSelect
        )
    }

    func contextMenu<M: View>(@ViewBuilder _ contextMenu: @escaping (PosterButtonType<Item>) -> M)
    -> PosterHStack<Header, Item, Content, ImageOverlay, M, TrailingContent> {
        .init(
            header: header,
            title: title,
            type: type,
            items: items,
            singleImage: singleImage,
            itemScale: itemScale,
            content: content,
            imageOverlay: imageOverlay,
            contextMenu: contextMenu,
            trailingContent: trailingContent,
            onSelect: onSelect
        )
    }

    func trailing<T: View>(@ViewBuilder _ trailingContent: @escaping () -> T)
    -> PosterHStack<Header, Item, Content, ImageOverlay, ContextMenu, T> {
        .init(
            header: header,
            title: title,
            type: type,
            items: items,
            singleImage: singleImage,
            itemScale: itemScale,
            content: content,
            imageOverlay: imageOverlay,
            contextMenu: contextMenu,
            trailingContent: trailingContent,
            onSelect: onSelect
        )
    }

    func onSelect(_ action: @escaping (Item) -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}
