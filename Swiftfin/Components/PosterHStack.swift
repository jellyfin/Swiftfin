//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import CollectionHStack
import SwiftUI

// TODO: Migrate to single `header: View`

struct PosterHStack<Element: Poster, Data: Collection>: View where Data.Element == Element, Data.Index == Int {

    private var data: Data
    private var header: () -> any View
    private var title: String?
    private var type: PosterDisplayType
    private var content: (Element) -> any View
    private var trailingContent: () -> any View
    private var action: (Element, Namespace.ID) -> Void

    private var layout: CollectionHStackLayout {
        if UIDevice.isPhone {
            return .grid(
                columns: type == .portrait ? 3 : 2,
                rows: 1,
                columnTrailingInset: 0
            )
        } else {
            return .minimumWidth(
                columnWidth: type == .portrait ? 140 : 220,
                rows: 1
            )
        }
    }

    @ViewBuilder
    private var stack: some View {
        CollectionHStack(
            uniqueElements: data,
            layout: layout
        ) { item in
            PosterButton(
                item: item,
                type: type
            ) { namespace in
                action(item, namespace)
            } label: {
                content(item).eraseToAnyView()
            }
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

            stack
        }
    }
}

extension PosterHStack {

    init(
        title: String? = nil,
        type: PosterDisplayType,
        items: Data,
        action: @escaping (Element, Namespace.ID) -> Void
    ) {
        self.init(
            data: items,
            header: { DefaultHeader(title: title) },
            title: title,
            type: type,
            content: { PosterButton.TitleSubtitleContentView(item: $0) },
            trailingContent: { EmptyView() },
            action: action
        )
    }

    func content(@ViewBuilder _ content: @escaping (Element) -> any View) -> Self {
        copy(modifying: \.content, with: content)
    }

    @available(*, deprecated, message: "Use `posterOverlay(for:)` instead")
    func imageOverlay(@ViewBuilder _ content: @escaping (Element) -> any View) -> Self {
        self
//        copy(modifying: \.imageOverlay, with: content)
    }

    func trailing(@ViewBuilder _ content: @escaping () -> any View) -> Self {
        copy(modifying: \.trailingContent, with: content)
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
