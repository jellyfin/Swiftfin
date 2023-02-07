//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: Remove `Header` and `TrailingContent` and create `HeaderPosterHStack`

struct PosterHStack<Item: Poster>: View {

    private var header: () -> any View
    private var title: String?
    private var type: PosterType
    private var items: [PosterButtonType<Item>]
    private var singleImage: Bool
    private var itemScale: CGFloat
    private var content: (PosterButtonType<Item>) -> any View
    private var imageOverlay: (PosterButtonType<Item>) -> any View
    private var contextMenu: (PosterButtonType<Item>) -> any View
    private var trailingContent: () -> any View
    private var onSelect: (Item) -> Void

    var body: some View {
        VStack(alignment: .leading) {

            HStack {
                header()
                    .eraseToAnyView()

                Spacer()

                trailingContent()
                    .eraseToAnyView()
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
                        .content { content($0).eraseToAnyView() }
                        .imageOverlay { imageOverlay($0).eraseToAnyView() }
                        .contextMenu { contextMenu($0).eraseToAnyView() }
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

extension PosterHStack {

    // TODO: Remove
    init(
        title: String,
        type: PosterType,
        items: [Item],
        singleImage: Bool = false
    ) {
        self.init(
            header: { DefaultHeader(title: title) },
            title: title,
            type: type,
            items: items.map { PosterButtonType.item($0) },
            singleImage: singleImage,
            itemScale: 1,
            content: { PosterButton.DefaultContentView(state: $0) },
            imageOverlay: { PosterButton.DefaultOverlay(state: $0) },
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
            header: { DefaultHeader(title: title) },
            title: title,
            type: type,
            items: items,
            singleImage: singleImage,
            itemScale: 1,
            content: { PosterButton.DefaultContentView(state: $0) },
            imageOverlay: { PosterButton.DefaultOverlay(state: $0) },
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
            header: { DefaultHeader(title: nil) },
            title: nil,
            type: type,
            items: items,
            singleImage: singleImage,
            itemScale: 1,
            content: { PosterButton.DefaultContentView(state: $0) },
            imageOverlay: { PosterButton.DefaultOverlay(state: $0) },
            contextMenu: { _ in EmptyView() },
            trailingContent: { EmptyView() },
            onSelect: { _ in }
        )
    }

    func header(@ViewBuilder _ header: @escaping () -> any View) -> Self {
        copy(modifying: \.header, with: header)
    }

    func scaleItems(_ scale: CGFloat) -> Self {
        copy(modifying: \.itemScale, with: scale)
    }

    func content(@ViewBuilder _ content: @escaping (PosterButtonType<Item>) -> any View) -> Self {
        copy(modifying: \.content, with: content)
    }

    func imageOverlay(@ViewBuilder _ content: @escaping (PosterButtonType<Item>) -> any View) -> Self {
        copy(modifying: \.imageOverlay, with: content)
    }

    func contextMenu(@ViewBuilder _ content: @escaping (PosterButtonType<Item>) -> any View) -> Self {
        copy(modifying: \.contextMenu, with: content)
    }

    func trailing(@ViewBuilder _ content: @escaping () -> any View) -> Self {
        copy(modifying: \.trailingContent, with: content)
    }

    func onSelect(_ action: @escaping (Item) -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}

// MARK: Default Header

extension PosterHStack {

    struct DefaultHeader: View {

        let title: String?

        var body: some View {
            if let title {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .accessibility(addTraits: [.isHeader])
            }
        }
    }
}
