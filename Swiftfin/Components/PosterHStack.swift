//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import CollectionHStack
import Defaults
import JellyfinAPI
import SwiftUI

// TODO: check accessibility

struct PosterHStack<
    Element: Poster,
    Data: Collection,
    Header: View,
    Label: View
>: View where Data.Element == Element, Data.Index == Int {

    @ForTypeInEnvironment<Element, (Any) -> PosterStyleEnvironment>(\.posterStyleRegistry)
    private var posterStyleRegistry

    @Router
    private var router

    private var data: Data
    private var header: Header
    private var title: String
    private var type: PosterDisplayType
    private var trailingContent: () -> any View
    private var action: (Element, Namespace.ID) -> Void

    private var posterStyle: PosterStyleEnvironment {
        guard let first = data.first else { return .default }
        return posterStyleRegistry?(first) ?? .default
    }

    private var layout: CollectionHStackLayout {
//        if UIDevice.isPhone {
//            return .grid(
//                columns: type == .landscape ? 2 : 3,
//                rows: 1,
//                columnTrailingInset: 0
//            )
//        } else {
//            return .minimumWidth(
//                columnWidth: type == .landscape ? 220 : 140,
//                rows: 1
//            )
//        }

        let columnCount: CGFloat = {
            switch posterStyle.displayType {
            case .landscape:
                1.5
            case .portrait:
                3
            case .square:
                3
            }
        }()

        return .grid(
            columns: columnCount,
            rows: 1,
            columnTrailingInset: 0
        )
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
                header

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

    func trailing(@ViewBuilder _ content: @escaping () -> any View) -> Self {
        copy(modifying: \.trailingContent, with: content)
    }
}

extension PosterHStack where Header == DefaultHeader {

    init(
        title: String,
        type: PosterDisplayType,
        items: Data,
        action: @escaping (Element, Namespace.ID) -> Void
    ) {
        self.init(
            data: items,
            header: DefaultHeader(title: title),
            title: title,
            type: type,
            trailingContent: { EmptyView() },
            action: action
        )
    }
}

extension PosterHStack where Header == DefaultHeader, Label == TitleSubtitleContentView {

    init(
        title: String,
        type: PosterDisplayType,
        items: Data,
        action: @escaping (Element, Namespace.ID) -> Void
    ) {
        self.init(
            data: items,
            header: DefaultHeader(title: title),
            title: title,
            type: type,
            trailingContent: { EmptyView() },
            action: action
        )
    }
}

// MARK: Default Header

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
