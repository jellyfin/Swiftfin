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

// MARK: - EPG

extension Collection<BaseItemDto> {

    func programBlocks(
        startDate: Date,
        endDate: Date,
        layout: EPGLayout
    ) -> [ProgramBlock] {
        let chunks = compactMap { ClampedProgram($0, clampedTo: startDate ... endDate) }
            .sorted(using: \.start)
            .chunked { $0.isShort && $1.isShort }

        return chunks.map { chunk in
            let start = chunk.first!.start
            let end = chunk.last!.end
            let leadingOffset = layout.width(from: startDate, to: start)

            return ProgramBlock(
                programs: chunk.map(\.program),
                start: start,
                end: end,
                leadingOffset: leadingOffset,
                width: layout.width(from: startDate, to: end) - leadingOffset
            )
        }
    }
}
