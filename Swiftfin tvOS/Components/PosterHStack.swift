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

// TODO: trailing content refactor?

struct PosterHStack<Element: Poster, Data: Collection>: View where Data.Element == Element, Data.Index == Int {

    private var data: Data
    private var title: String?
    private var type: PosterDisplayType
    private var content: (Element) -> any View
    private var imageOverlay: (Element) -> any View
    private var contextMenu: (Element) -> any View
    private var trailingContent: () -> any View
    private var action: (Element) -> Void

    // See PosterButton for implementation reason
    private var focusedItem: Binding<Element?>?

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
                uniqueElements: data,
                columns: type == .landscape ? 4 : 7
            ) { item in
                PosterButton(
                    item: item,
                    type: type
                ) {
                    action(item)
                } label: {
                    content(item).eraseToAnyView()
                }
            }
            .clipsToBounds(false)
            .dataPrefix(20)
            .insets(horizontal: EdgeInsets.edgePadding, vertical: 20)
            .itemSpacing(EdgeInsets.edgePadding - 20)
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
        type: PosterDisplayType,
        items: Data,
        action: @escaping (Element) -> Void
    ) {
        self.init(
            data: items,
            title: title,
            type: type,
            content: { PosterButton.TitleSubtitleContentView(item: $0) },
            imageOverlay: { PosterButton.DefaultOverlay(item: $0) },
            contextMenu: { _ in EmptyView() },
            trailingContent: { EmptyView() },
            action: action
        )
    }

    func content(@ViewBuilder _ content: @escaping (Element) -> any View) -> Self {
        copy(modifying: \.content, with: content)
    }

    @available(*, deprecated, message: "Use `posterOverlay(for:)` instead")
    func imageOverlay(@ViewBuilder _ content: @escaping (Element) -> any View) -> Self {
        copy(modifying: \.imageOverlay, with: content)
    }

    @available(*, deprecated, message: "Use `contextMenu(for:)` instead")
    func contextMenu(@ViewBuilder _ content: @escaping (Element) -> any View) -> Self {
        copy(modifying: \.contextMenu, with: content)
    }

    func trailing(@ViewBuilder _ content: @escaping () -> any View) -> Self {
        copy(modifying: \.trailingContent, with: content)
    }

    @available(*, deprecated, message: "Use init with action instead")
    func onSelect(_ action: @escaping (Element) -> Void) -> Self {
        self
//        copy(modifying: \.action, with: action)
    }

    func focusedItem(_ binding: Binding<Element?>) -> Self {
        copy(modifying: \.focusedItem, with: binding)
    }
}
