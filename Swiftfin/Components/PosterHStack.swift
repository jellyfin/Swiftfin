//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import CollectionHStack
import OrderedCollections
import SwiftUI

struct PosterHStack<Item: Poster>: View {

    private var header: () -> any View
    private var title: String?
    private var type: PosterType
    private var items: Binding<OrderedSet<Item>>
    private var singleImage: Bool
    private var content: (Item) -> any View
    private var imageOverlay: (Item) -> any View
    private var contextMenu: (Item) -> any View
    private var trailingContent: () -> any View
    private var onSelect: (Item) -> Void

    @ViewBuilder
    private var padHStack: some View {
        CollectionHStack(
            items,
            minWidth: type == .portrait ? 140 : 220
        ) { item in
            PosterButton(
                item: item,
                type: type,
                singleImage: singleImage
            )
            .content { content(item).eraseToAnyView() }
            .imageOverlay { imageOverlay(item).eraseToAnyView() }
            .contextMenu { contextMenu(item).eraseToAnyView() }
            .onSelect { onSelect(item) }
        }
        .clipsToBounds(false)
        .dataPrefix(20)
        .insets(horizontal: EdgeInsets.defaultEdgePadding)
        .itemSpacing(EdgeInsets.defaultEdgePadding / 2)
        .scrollBehavior(.continuousLeadingEdge)
    }

    @ViewBuilder
    private var phoneHStack: some View {
        CollectionHStack(
            items,
            columns: type == .portrait ? 3 : 2
        ) { item in
            PosterButton(
                item: item,
                type: type,
                singleImage: singleImage
            )
            .content { content(item).eraseToAnyView() }
            .imageOverlay { imageOverlay(item).eraseToAnyView() }
            .contextMenu { contextMenu(item).eraseToAnyView() }
            .onSelect { onSelect(item) }
        }
        .clipsToBounds(false)
        .dataPrefix(20)
        .insets(horizontal: EdgeInsets.defaultEdgePadding)
        .itemSpacing(EdgeInsets.defaultEdgePadding / 2)
        .scrollBehavior(.continuousLeadingEdge)
    }

    var body: some View {
        VStack(alignment: .leading) {

            HStack {
                header()
                    .eraseToAnyView()

                Spacer()

                trailingContent()
                    .eraseToAnyView()
            }
            .edgePadding(.horizontal)

            if UIDevice.isPhone {
                phoneHStack
            } else {
                padHStack
            }
        }
    }
}

extension PosterHStack {

    init(
        title: String? = nil,
        type: PosterType,
        items: Binding<OrderedSet<Item>>,
        singleImage: Bool = false
    ) {
        self.init(
            header: { DefaultHeader(title: title) },
            title: title,
            type: type,
            items: items,
            singleImage: singleImage,
            content: { PosterButton.TitleSubtitleContentView(item: $0) },
            imageOverlay: { PosterButton.DefaultOverlay(item: $0) },
            contextMenu: { _ in EmptyView() },
            trailingContent: { EmptyView() },
            onSelect: { _ in }
        )
    }

    init<S: Sequence<Item>>(
        title: String? = nil,
        type: PosterType,
        items: S,
        singleImage: Bool = false
    ) {
        self.init(
            title: title,
            type: type,
            items: .constant(OrderedSet(items)),
            singleImage: singleImage
        )
    }

    func header(@ViewBuilder _ header: @escaping () -> any View) -> Self {
        copy(modifying: \.header, with: header)
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
