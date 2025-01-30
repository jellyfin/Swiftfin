//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import CollectionHStack
import OrderedCollections
import SwiftUI

struct PosterHStack<Element: Poster & Identifiable, Data: Collection>: View where Data.Element == Element, Data.Index == Int {

    private var data: Data
    private var header: () -> any View
    private var title: String?
    private var type: PosterDisplayType
    private var content: (Element) -> any View
    private var imageOverlay: (Element) -> any View
    private var contextMenu: (Element) -> any View
    private var trailingContent: () -> any View
    private var onSelect: (Element) -> Void

    @ViewBuilder
    private var padHStack: some View {
        CollectionHStack(
            uniqueElements: data,
            minWidth: type == .portrait ? 140 : 220
        ) { item in
            PosterButton(
                item: item,
                type: type
            )
            .content { content(item).eraseToAnyView() }
            .imageOverlay { imageOverlay(item).eraseToAnyView() }
            .contextMenu { contextMenu(item).eraseToAnyView() }
            .onSelect { onSelect(item) }
        }
        .clipsToBounds(false)
        .dataPrefix(20)
        .insets(horizontal: EdgeInsets.edgePadding)
        .itemSpacing(EdgeInsets.edgePadding / 2)
        .scrollBehavior(.continuousLeadingEdge)
    }

    @ViewBuilder
    private var phoneHStack: some View {
        CollectionHStack(
            uniqueElements: data,
            columns: type == .portrait ? 3 : 2
        ) { item in
            PosterButton(
                item: item,
                type: type
            )
            .content { content(item).eraseToAnyView() }
            .imageOverlay { imageOverlay(item).eraseToAnyView() }
            .contextMenu { contextMenu(item).eraseToAnyView() }
            .onSelect { onSelect(item) }
        }
        .clipsToBounds(false)
        .dataPrefix(20)
        .insets(horizontal: EdgeInsets.edgePadding)
        .itemSpacing(EdgeInsets.edgePadding / 2)
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
        type: PosterDisplayType,
        items: Data
    ) {
        self.init(
            data: items,
            header: { DefaultHeader(title: title) },
            title: title,
            type: type,
            content: { PosterButton.TitleSubtitleContentView(item: $0) },
            imageOverlay: { PosterButton.DefaultOverlay(item: $0) },
            contextMenu: { _ in EmptyView() },
            trailingContent: { EmptyView() },
            onSelect: { _ in }
        )
    }

    func header(@ViewBuilder _ header: @escaping () -> any View) -> Self {
        copy(modifying: \.header, with: header)
    }

    func content(@ViewBuilder _ content: @escaping (Element) -> any View) -> Self {
        copy(modifying: \.content, with: content)
    }

    func imageOverlay(@ViewBuilder _ content: @escaping (Element) -> any View) -> Self {
        copy(modifying: \.imageOverlay, with: content)
    }

    func contextMenu(@ViewBuilder _ content: @escaping (Element) -> any View) -> Self {
        copy(modifying: \.contextMenu, with: content)
    }

    func trailing(@ViewBuilder _ content: @escaping () -> any View) -> Self {
        copy(modifying: \.trailingContent, with: content)
    }

    func onSelect(_ action: @escaping (Element) -> Void) -> Self {
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
