//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Algorithms
import Foundation
import JellyfinAPI

extension Collection {

    var asArray: [Element] {
        Array(self)
    }

    var isNotEmpty: Bool {
        !isEmpty
    }

    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }

    func keyed<Key>(using keyPath: KeyPath<Element, Key>) -> [Key: Element] {
        Dictionary(uniqueKeysWithValues: map { ($0[keyPath: keyPath], $0) })
    }
}

// MARK: - Live TV Guide

extension Collection<BaseItemDto> {

    func programBlocks(
        startDate: Date,
        endDate: Date,
        layout: LiveTVGuideLayout
    ) -> [ProgramBlock] {
        let chunks = compactMap { ClampedProgram($0, clampedTo: startDate ... endDate) }
            .sorted(using: \.start)
            .chunked { $0.isShort && $1.isShort }

        var result: [ProgramBlock] = []
        var occupiedWidth: CGFloat = 0

        for chunk in chunks {
            let start = chunk.first!.start
            let end = chunk.last!.end
            let leadingOffset = Swift.max(layout.width(from: startDate, to: start), occupiedWidth)
            let trailingOffset = layout.width(from: startDate, to: end)
            let width = Swift.max(trailingOffset - leadingOffset, layout.minimumCellWidth)

            result.append(
                ProgramBlock(
                    programs: chunk.map(\.program),
                    start: start,
                    end: end,
                    leadingOffset: leadingOffset,
                    width: width
                )
            )
            occupiedWidth = leadingOffset + width
        }

        return result
    }
}
