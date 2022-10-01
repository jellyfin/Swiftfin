//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import CollectionView
import SwiftUI

struct PosterHStack<Header: View, Item: Poster, Content: View, ImageOverlay: View, ContextMenu: View, TrailingContent: View>: View {

    private var header: () -> Header
    private var title: String?
    private var type: PosterType
    private var state: PosterHStackState<Item>
    private var singleImage: Bool
    private var itemScale: CGFloat
    private var content: (Item) -> Content
    private var imageOverlay: (Item) -> ImageOverlay
    private var contextMenu: (Item) -> ContextMenu
    private var trailingContent: () -> TrailingContent
    private var onSelect: (Item) -> Void

    @ViewBuilder
    private var loadingContent: some View {
        ForEach(0 ..< Int.random(in: 4 ... 7), id: \.self) { _ in
            PosterButton(
                state: PosterButtonState<Item>.loading,
                type: type
            )
            .scaleItem(itemScale)
        }
    }

    @ViewBuilder
    private var noResultsContent: some View {
        PosterButton(
            state: PosterButtonState<Item>.noResult,
            type: type
        )
        .scaleItem(itemScale)
    }

    @ViewBuilder
    private func itemsContent(from items: [Item]) -> some View {
        ForEach(items, id: \.hashValue) { item in
            PosterButton(
                state: .item(item),
                type: type,
                singleImage: singleImage
            )
            .scaleItem(itemScale)
            .content { content(item) }
            .imageOverlay { imageOverlay(item) }
            .contextMenu { contextMenu(item) }
            .onSelect { onSelect(item) }
        }
    }

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
                    switch state {
                    case .loading:
                        loadingContent
                    case .noResults:
                        noResultsContent
                    case let .items(items):
                        itemsContent(from: items)
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
            state: .items(items),
            singleImage: singleImage,
            itemScale: 1,
            content: { PosterButtonDefaultContentView(state: .item($0)) },
            imageOverlay: { _ in EmptyView() },
            contextMenu: { _ in EmptyView() },
            trailingContent: { EmptyView() },
            onSelect: { _ in }
        )
    }

    init(
        title: String,
        type: PosterType,
        state: PosterHStackState<Item>,
        singleImage: Bool = false
    ) {
        self.init(
            header: { EmptyView() },
            title: title,
            type: type,
            state: state,
            singleImage: singleImage,
            itemScale: 1,
            content: {
                switch state {
                case .loading:
                    return PosterButtonDefaultContentView(state: PosterButtonState<Item>.loading)
                case .noResults:
                    return PosterButtonDefaultContentView(state: PosterButtonState<Item>.noResult)
                case .items:
                    return PosterButtonDefaultContentView(state: PosterButtonState<Item>.item($0))
                }
            },
            imageOverlay: { _ in EmptyView() },
            contextMenu: { _ in EmptyView() },
            trailingContent: { EmptyView() },
            onSelect: { _ in }
        )
    }

    init(
        type: PosterType,
        state: PosterHStackState<Item>,
        singleImage: Bool = false
    ) {
        self.init(
            header: { EmptyView() },
            title: nil,
            type: type,
            state: state,
            singleImage: singleImage,
            itemScale: 1,
            content: {
                switch state {
                case .loading:
                    return PosterButtonDefaultContentView(state: PosterButtonState<Item>.loading)
                case .noResults:
                    return PosterButtonDefaultContentView(state: PosterButtonState<Item>.noResult)
                case .items:
                    return PosterButtonDefaultContentView(state: PosterButtonState<Item>.item($0))
                }
            },
            imageOverlay: { _ in EmptyView() },
            contextMenu: { _ in EmptyView() },
            trailingContent: { EmptyView() },
            onSelect: { _ in }
        )
    }
}

extension PosterHStack {

    @ViewBuilder
    func header<H: View>(@ViewBuilder _ header: @escaping () -> H)
    -> PosterHStack<H, Item, Content, ImageOverlay, ContextMenu, TrailingContent> {
        PosterHStack<H, Item, Content, ImageOverlay, ContextMenu, TrailingContent>(
            header: header,
            title: title,
            type: type,
            state: state,
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

    @ViewBuilder
    func content<C: View>(@ViewBuilder _ content: @escaping (Item) -> C)
    -> PosterHStack<Header, Item, C, ImageOverlay, ContextMenu, TrailingContent> {
        PosterHStack<Header, Item, C, ImageOverlay, ContextMenu, TrailingContent>(
            header: header,
            title: title,
            type: type,
            state: state,
            singleImage: singleImage,
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
    -> PosterHStack<Header, Item, Content, O, ContextMenu, TrailingContent> {
        PosterHStack<Header, Item, Content, O, ContextMenu, TrailingContent>(
            header: header,
            title: title,
            type: type,
            state: state,
            singleImage: singleImage,
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
    -> PosterHStack<Header, Item, Content, ImageOverlay, M, TrailingContent> {
        PosterHStack<Header, Item, Content, ImageOverlay, M, TrailingContent>(
            header: header,
            title: title,
            type: type,
            state: state,
            singleImage: singleImage,
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
    -> PosterHStack<Header, Item, Content, ImageOverlay, ContextMenu, T> {
        PosterHStack<Header, Item, Content, ImageOverlay, ContextMenu, T>(
            header: header,
            title: title,
            type: type,
            state: state,
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
