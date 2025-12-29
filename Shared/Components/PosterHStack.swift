//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import CollectionHStack
import SwiftUI

// TODO: check accessibility

struct PosterHStack<
    Data: Collection,
    Header: View
>: View where Data.Element: Poster, Data.Index == Int {

    private let elements: Data
    private let header: Header
    private let displayType: PosterDisplayType
    private let size: PosterDisplayType.Size

    private var action: (Data.Element, Namespace.ID) -> Void

    private var layout: CollectionHStackLayout {
        #if os(tvOS)
        .grid(
            columns: displayType == .landscape ? 5 : 7,
            rows: 1,
            columnTrailingInset: 0
        )
        #else
        if UIDevice.isPad {
            let minWidth: CGFloat = {
                switch (displayType, size) {
                case (.landscape, .small):
                    220
                case (.landscape, .medium):
                    300
                case (_, .small):
                    140
                case (_, .medium):
                    200
                }
            }()

            return .minimumWidth(
                columnWidth: minWidth,
                rows: 1
            )
        } else {
            let columnCount: CGFloat = {
                switch (displayType, size) {
                case (.landscape, .small):
                    2
                case (.landscape, .medium):
                    1.5
                case (_, .small):
                    3
                case (_, .medium):
                    2
                }
            }()

            return .grid(
                columns: columnCount,
                rows: 1,
                columnTrailingInset: 0
            )
        }
        #endif
    }

    private var itemSpacing: CGFloat {
        #if os(tvOS)
        EdgeInsets.edgePadding - 10
        #else
        EdgeInsets.edgePadding / 2
        #endif
    }

    @ViewBuilder
    private var stack: some View {
        if elements.isNotEmpty {
            CollectionHStack(
                uniqueElements: elements,
                layout: layout
            ) { item in
                PosterButton(
                    item: item,
                    type: displayType,
                    size: size
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
    }

    var body: some View {
//        let _ = Self._printChanges()

        Section {
            stack
        } header: {
            header
        }
    }
}

extension PosterHStack {

    init(
        elements: Data,
        type: PosterDisplayType,
        size: PosterDisplayType.Size = .small,
        action: @escaping (Data.Element, Namespace.ID) -> Void,
        @ViewBuilder header: () -> Header
    ) {
        self.elements = elements
        self.header = header()
        self.displayType = type
        self.size = size
        self.action = action
    }
}

extension PosterHStack where Header == DefaultHeader {

    init(
        title: String,
        elements: Data,
        type: PosterDisplayType,
        size: PosterDisplayType.Size = .small,
        action: @escaping (Data.Element, Namespace.ID) -> Void
    ) {
        self.init(
            elements: elements,
            type: type,
            size: size,
            action: action,
            header: { DefaultHeader(title: title) }
        )
    }
}

// MARK: Default Header

struct DefaultHeader: View {

    let title: String

    var body: some View {
        Text(title)
            .font(.title2)
            .fontWeight(.semibold)
            .accessibilityAddTraits(.isHeader)
            .edgePadding(.horizontal)
    }
}
