//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct PortraitPosterHStack<Item: PortraitPoster, Content: View, ImageOverlay: View, ContextMenu: View, TrailingContent: View>: View {

    private let title: String
    private let items: [Item]
    private let itemScale: CGFloat
    private let content: (Item) -> Content
    private let imageOverlay: (Item) -> ImageOverlay
    private let contextMenu: (Item) -> ContextMenu
    private let trailingContent: () -> TrailingContent
    private let selectedAction: (Item) -> Void

    private init(
        title: String,
        items: [Item],
        itemScale: CGFloat,
        @ViewBuilder content: @escaping (Item) -> Content,
        @ViewBuilder imageOverlay: @escaping (Item) -> ImageOverlay,
        @ViewBuilder contextMenu: @escaping (Item) -> ContextMenu,
        @ViewBuilder trailingContent: @escaping () -> TrailingContent,
        selectedAction: @escaping (Item) -> Void
    ) {
        self.title = title
        self.items = items
        self.itemScale = itemScale
        self.content = content
        self.imageOverlay = imageOverlay
        self.contextMenu = contextMenu
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
                        PortraitPosterButton(item: item)
                            .scaleItem(itemScale)
                            .imageOverlay(imageOverlay)
                            .selectedAction(selectedAction)
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

extension PortraitPosterHStack where Content == PosterButtonDefaultContentView<Item>,
    ImageOverlay == EmptyView,
    ContextMenu == EmptyView,
    TrailingContent == EmptyView
{
    init(
        title: String,
        items: [Item]
    ) {
        self.init(
            title: title,
            items: items,
            itemScale: 1,
            content: { PosterButtonDefaultContentView(item: $0) },
            imageOverlay: { _ in EmptyView() },
            contextMenu: { _ in EmptyView() },
            trailingContent: { EmptyView() },
            selectedAction: { _ in }
        )
    }
}

extension PortraitPosterHStack {
    @ViewBuilder
    func scaleItems(_ scale: CGFloat) -> PortraitPosterHStack {
        PortraitPosterHStack(
            title: title,
            items: items,
            itemScale: scale,
            content: content,
            imageOverlay: imageOverlay,
            contextMenu: contextMenu,
            trailingContent: trailingContent,
            selectedAction: selectedAction
        )
    }

    @ViewBuilder
    func content<C: View>(@ViewBuilder _ content: @escaping (Item) -> C)
    -> PortraitPosterHStack<Item, C, ImageOverlay, ContextMenu, TrailingContent> {
        PortraitPosterHStack<Item, C, ImageOverlay, ContextMenu, TrailingContent>(
            title: title,
            items: items,
            itemScale: itemScale,
            content: content,
            imageOverlay: imageOverlay,
            contextMenu: contextMenu,
            trailingContent: trailingContent,
            selectedAction: selectedAction
        )
    }

    @ViewBuilder
    func imageOverlay<O: View>(@ViewBuilder _ imageOverlay: @escaping (Item) -> O)
    -> PortraitPosterHStack<Item, Content, O, ContextMenu, TrailingContent> {
        PortraitPosterHStack<Item, Content, O, ContextMenu, TrailingContent>(
            title: title,
            items: items,
            itemScale: itemScale,
            content: content,
            imageOverlay: imageOverlay,
            contextMenu: contextMenu,
            trailingContent: trailingContent,
            selectedAction: selectedAction
        )
    }

    @ViewBuilder
    func contextMenu<M: View>(@ViewBuilder _ contextMenu: @escaping (Item) -> M)
    -> PortraitPosterHStack<Item, Content, ImageOverlay, M, TrailingContent> {
        PortraitPosterHStack<Item, Content, ImageOverlay, M, TrailingContent>(
            title: title,
            items: items,
            itemScale: itemScale,
            content: content,
            imageOverlay: imageOverlay,
            contextMenu: contextMenu,
            trailingContent: trailingContent,
            selectedAction: selectedAction
        )
    }

    @ViewBuilder
    func trailing<T: View>(@ViewBuilder _ trailingContent: @escaping () -> T)
    -> PortraitPosterHStack<Item, Content, ImageOverlay, ContextMenu, T> {
        PortraitPosterHStack<Item, Content, ImageOverlay, ContextMenu, T>(
            title: title,
            items: items,
            itemScale: itemScale,
            content: content,
            imageOverlay: imageOverlay,
            contextMenu: contextMenu,
            trailingContent: trailingContent,
            selectedAction: selectedAction
        )
    }

    @ViewBuilder
    func selectedAction(_ selectedAction: @escaping (Item) -> Void) -> PortraitPosterHStack {
        PortraitPosterHStack(
            title: title,
            items: items,
            itemScale: itemScale,
            content: content,
            imageOverlay: imageOverlay,
            contextMenu: contextMenu,
            trailingContent: trailingContent,
            selectedAction: selectedAction
        )
    }
}
