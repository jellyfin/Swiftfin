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

// TODO: trailing content refactor?

struct PosterHStack<Item: Poster>: View {

    private var title: String?
    private var type: PosterType
    private var items: Binding<OrderedSet<Item>>
    private var content: (Item) -> any View
    private var imageOverlay: (Item) -> any View
    private var contextMenu: (Item) -> any View
    private var trailingContent: () -> any View
    private var onSelect: (Item) -> Void

    // See PosterButton for implementation reason
    private var focusedItem: Binding<Item?>?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {

            if let title {
                HStack {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .accessibility(addTraits: [.isHeader])
                        .padding(.leading, 50)

                    Spacer()
                }
            }

            CollectionHStack(
                items,
                columns: type == .landscape ? 4 : 7
            ) { item in
                PosterButton(item: item, type: type)
                    .content { content(item).eraseToAnyView() }
                    .imageOverlay { imageOverlay(item).eraseToAnyView() }
                    .contextMenu { contextMenu(item).eraseToAnyView() }
                    .onSelect { onSelect(item) }
                    .ifLet(focusedItem) { view, focusedItem in
                        view.onFocusChanged { isFocused in
                            if isFocused { focusedItem.wrappedValue = item }
                        }
                    }
            }
            .clipsToBounds(false)
            .dataPrefix(20)
            .insets(horizontal: EdgeInsets.defaultEdgePadding, vertical: 20)
            .itemSpacing(EdgeInsets.defaultEdgePadding - 20)
            .scrollBehavior(.continuousLeadingEdge)
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
        items: Binding<OrderedSet<Item>>
    ) {
        self.init(
            title: title,
            type: type,
            items: items,
            content: { PosterButton.TitleSubtitleContentView(item: $0) },
            imageOverlay: { PosterButton.DefaultOverlay(item: $0) },
            contextMenu: { _ in EmptyView() },
            trailingContent: { EmptyView() },
            onSelect: { _ in },
            focusedItem: nil
        )
    }

    init<S: Sequence<Item>>(
        title: String? = nil,
        type: PosterType,
        items: S
    ) {
        self.init(
            title: title,
            type: type,
            items: .constant(OrderedSet(items))
        )
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
