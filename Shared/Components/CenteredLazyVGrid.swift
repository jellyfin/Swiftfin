//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

/// A LazyVGrid that centers its elements, most notably on the last row.
struct CenteredLazyVGrid<Data: RandomAccessCollection, ID: Hashable, Content: View>: View {

    @State
    private var elementSize: CGSize = .zero

    private let columnCount: Int
    private let columns: [GridItem]
    private let content: (Data.Element) -> Content
    private let data: Data
    private let id: KeyPath<Data.Element, ID>
    private let spacing: CGFloat

    /// Calculates the x offset for elements in
    /// the last row of the grid to be centered.
    private func elementXOffset(for offset: Int) -> CGFloat {
        let dataCount = data.count
        let lastRowCount = dataCount % columnCount

        guard lastRowCount > 0 else { return 0 }

        let lastRowIndices = (dataCount - lastRowCount ..< dataCount)

        guard lastRowIndices.contains(offset) else { return 0 }

        let lastRowMissingCount = columnCount - lastRowCount
        return CGFloat(lastRowMissingCount) * (elementSize.width + spacing) / 2
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: spacing) {
            ForEach(Array(data.enumerated()), id: \.offset) { offset, element in
                content(element)
                    .trackingSize($elementSize)
                    .offset(x: elementXOffset(for: offset))
            }
        }
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
        self.columnCount = columns
        self.content = content
        self.data = data
        self.id = id
        self.spacing = spacing

        self.columns = Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns)
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
