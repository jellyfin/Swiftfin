//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

/// A LazyVGrid that centers its elements, most notably on the last row.
struct CenteredLazyVGrid<Data: RandomAccessCollection, ID: Hashable, Content: View>: View {

    private let innerContent: () -> any View

    var body: some View {
        innerContent()
            .eraseToAnyView()
    }
}

extension CenteredLazyVGrid {

    init(
        data: Data,
        id: KeyPath<Data.Element, ID>,
        columns: Int,
        spacing: CGFloat = 0,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.innerContent = {
            FixedColumnContentView(
                columnCount: columns,
                content: content,
                data: data,
                id: id,
                spacing: spacing
            )
        }
    }

    init(
        data: Data,
        id: KeyPath<Data.Element, ID>,
        minimum: CGFloat,
        maximum: CGFloat,
        spacing: CGFloat = 0,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.innerContent = {
            AdaptiveContentView(
                content: content,
                data: data,
                id: id,
                maximum: maximum,
                minimum: minimum,
                spacing: spacing
            )
        }
    }
}

extension CenteredLazyVGrid where Data.Element: Identifiable, ID == Data.Element.ID {

    init(
        data: Data,
        columns: Int,
        spacing: CGFloat = 0,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.init(
            data: data,
            id: \.id,
            columns: columns,
            spacing: spacing,
            content: content
        )
    }

    init(
        data: Data,
        minimum: CGFloat,
        maximum: CGFloat,
        spacing: CGFloat = 0,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.init(
            data: data,
            id: \.id,
            minimum: minimum,
            maximum: maximum,
            spacing: spacing,
            content: content
        )
    }
}

extension CenteredLazyVGrid {

    private struct AdaptiveContentView: View {

        @State
        private var contentSize: CGSize = .zero
        @State
        private var elementSize: CGSize = .zero

        let content: (Data.Element) -> Content
        let data: Data
        let id: KeyPath<Data.Element, ID>
        let maximum: CGFloat
        let minimum: CGFloat
        let spacing: CGFloat

        private var enumeratedId: KeyPath<EnumeratedSequence<Data>.Element, ID> {
            let element = \EnumeratedSequence<Data>.Element.element
            return element.appending(path: id)
        }

        private var columnCount: Int? {
            let elementSizeAndWidth = elementSize.width + spacing
            guard elementSizeAndWidth > 0 else { return nil }

            let additionalPadding = data.count >= 1 ? spacing : 0

            return Int((contentSize.width + additionalPadding) / elementSizeAndWidth)
        }

        private func elementXOffset(for offset: Int) -> CGFloat {
            guard let columnCount, columnCount > 0 else { return 0 }
            let dataCount = data.count
            let lastRowCount = dataCount % columnCount

            guard lastRowCount > 0 else { return 0 }

            let lastRowIndices = (dataCount - lastRowCount ..< dataCount)

            guard lastRowIndices.contains(offset) else { return 0 }

            let lastRowMissingCount = columnCount - lastRowCount
            return CGFloat(lastRowMissingCount) * (elementSize.width + spacing) / 2
        }

        var body: some View {
            let columns: [GridItem] = [GridItem(
                .adaptive(minimum: minimum, maximum: maximum),
                spacing: spacing
            )]

            LazyVGrid(columns: columns, spacing: spacing) {
                ForEach(Array(data.enumerated()), id: enumeratedId) { offset, element in
                    content(element)
                        .trackingSize($elementSize)
                        .offset(x: elementXOffset(for: offset))
                }
            }
            .trackingSize($contentSize)
        }
    }
}

extension CenteredLazyVGrid {

    private struct FixedColumnContentView: View {

        @State
        private var elementSize: CGSize = .zero

        let columnCount: Int
        let content: (Data.Element) -> Content
        let data: Data
        let id: KeyPath<Data.Element, ID>
        let spacing: CGFloat

        private var enumeratedId: KeyPath<EnumeratedSequence<Data>.Element, ID> {
            let element = \EnumeratedSequence<Data>.Element.element
            return element.appending(path: id)
        }

        /// Calculates the x offset for elements in
        /// the last row of the grid to be centered.
        private func elementXOffset(for offset: Int) -> CGFloat {
            let columnCount = columnCount
            let dataCount = data.count
            let lastRowCount = dataCount % columnCount

            guard lastRowCount > 0 else { return 0 }

            let lastRowIndices = (dataCount - lastRowCount ..< dataCount)

            guard lastRowIndices.contains(offset) else { return 0 }

            let lastRowMissingCount = columnCount - lastRowCount
            return CGFloat(lastRowMissingCount) * (elementSize.width + spacing) / 2
        }

        var body: some View {
            let columns = Array(
                repeating: GridItem(
                    .flexible(),
                    spacing: spacing
                ),
                count: columnCount
            )

            LazyVGrid(columns: columns, spacing: spacing) {
                ForEach(Array(data.enumerated()), id: enumeratedId) { offset, element in
                    content(element)
                        .trackingSize($elementSize)
                        .offset(x: elementXOffset(for: offset))
                }
            }
        }
    }
}
