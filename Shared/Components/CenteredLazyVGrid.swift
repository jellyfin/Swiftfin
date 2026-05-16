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

    let data: Data
    let id: KeyPath<Data.Element, ID>
    let columns: Int
    var spacing: CGFloat = 0
    let content: (Data.Element) -> Content

    var body: some View {
        FixedColumnContentView(
            columns: columns,
            content: content,
            data: data,
            id: id,
            spacing: spacing
        )
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
}

extension CenteredLazyVGrid {

    private struct FixedColumnContentView: View {

        @State
        private var elementSize: CGSize = .zero

        let columns: Int
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
            let dataCount = data.count
            let lastRowCount = dataCount % columns

            guard lastRowCount > 0 else { return 0 }

            let lastRowIndices = (dataCount - lastRowCount ..< dataCount)

            guard lastRowIndices.contains(offset) else { return 0 }

            let lastRowMissingCount = columns - lastRowCount
            return CGFloat(lastRowMissingCount) * (elementSize.width + spacing) / 2
        }

        var body: some View {
            let columns = Array(
                repeating: GridItem(
                    .flexible(),
                    spacing: spacing
                ),
                count: columns
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
