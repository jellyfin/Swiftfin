//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CollectionHStack
import CollectionVGrid
import SwiftUI

extension VideoPlayer {

    struct PosterCollectionView<Data: RandomAccessCollection, Content: View>: PlatformView
        where Data.Element: Poster, Data.Index == Int
    {

        @Environment(\.safeAreaInsets)
        private var safeAreaInsets

        @State
        private var initialElementID: Data.Element.ID?

        private let data: Data
        private let currentElementID: Data.Element.ID?
        private let isCompact: Bool
        private let displayType: PosterDisplayType
        private let size: PosterDisplayType.Size
        private let action: (Data.Element) -> Void
        private let content: (Data.Element) -> Content

        init(
            data: Data,
            currentElementID: Data.Element.ID? = nil,
            isCompact: Bool,
            displayType: PosterDisplayType = .landscape,
            size: PosterDisplayType.Size = .small,
            action: @escaping (Data.Element) -> Void,
            @ViewBuilder content: @escaping (Data.Element) -> Content
        ) {
            self.data = data
            self.currentElementID = currentElementID
            self._initialElementID = State(initialValue: currentElementID)
            self.isCompact = isCompact
            self.displayType = displayType
            self.size = size
            self.action = action
            self.content = content
        }

        private func isCurrent(_ element: Data.Element) -> Bool {
            guard let currentElementID else { return false }

            return element.id == currentElementID
        }

        @ViewBuilder
        private func elementRow(_ element: Data.Element) -> some View {
            ListRow(insets: .init(horizontal: EdgeInsets.edgePadding)) {
                PosterImage(item: element, type: displayType, size: size)
                    .overlay { element.posterOverlay(for: displayType).posterStyle(displayType) }
                    .subtleShadow()
                    .hoverEffect(.highlight)
                    .frame(width: 110)
                    .padding(.vertical, 8)
            } content: {
                content(element)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } action: {
                action(element)
            }
            .environment(\.posterDisplayType, displayType)
            .isSelected(isCurrent(element))
            .accessibilityAddTraits(isCurrent(element) ? .isSelected : [])
        }

        @ViewBuilder
        private func elementButton(_ element: Data.Element) -> some View {
            PosterButton(item: element, displayType: displayType, size: size) { _ in
                action(element)
            }
            .isSelected(isCurrent(element))
            .accessibilityAddTraits(isCurrent(element) ? .isSelected : [])
        }

        var iOSView: some View {
            CompactOrRegularView(isCompact: isCompact) {
                CollectionVGrid(
                    uniqueElements: data,
                    id: \.id,
                    layout: .columns(
                        1,
                        insets: .edgeInsets,
                        itemSpacing: EdgeInsets.itemSpacing,
                        lineSpacing: EdgeInsets.itemSpacing
                    ),
                    viewProvider: elementRow
                )
            } regularView: {
                CollectionHStack(
                    uniqueElements: data,
                    id: \.id,
                    layout: .minimumWidth(columnWidth: 170, rows: 1),
                    content: elementButton
                )
                .initialElement(id: initialElementID)
                .clipsToBounds(false)
                .insets(horizontal: max(safeAreaInsets.leading, safeAreaInsets.trailing) + EdgeInsets.edgePadding)
                .itemSpacing(EdgeInsets.itemSpacing)
                .scrollBehavior(.continuousLeadingEdge)
            }
            .onChange(of: currentElementID) { _, newID in
                if initialElementID == nil {
                    initialElementID = newID
                }
            }
        }

        var tvOSView: some View {
            CollectionHStack(
                uniqueElements: data,
                id: \.id,
                layout: .grid(columns: displayType == .landscape ? 5 : 7, rows: 1, columnTrailingInset: 0),
                content: elementButton
            )
            .initialElement(id: initialElementID)
            .insets(horizontal: EdgeInsets.edgePadding)
            .itemSpacing(EdgeInsets.itemSpacing)
            .ignoresSafeArea(.container, edges: .horizontal)
            .frame(maxHeight: .infinity)
            .focusSection()
            .onChange(of: currentElementID) { _, newID in
                if initialElementID == nil {
                    initialElementID = newID
                }
            }
        }
    }
}

extension VideoPlayer.PosterCollectionView where Content == Data.Element.LabelBody {

    init(
        data: Data,
        currentElementID: Data.Element.ID? = nil,
        isCompact: Bool,
        displayType: PosterDisplayType = .landscape,
        size: PosterDisplayType.Size = .small,
        action: @escaping (Data.Element) -> Void
    ) {
        self.init(
            data: data,
            currentElementID: currentElementID,
            isCompact: isCompact,
            displayType: displayType,
            size: size,
            action: action,
            content: { $0.posterLabel }
        )
    }
}
