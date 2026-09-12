//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

struct LibraryPageSlot<Element: Identifiable>: Identifiable {
    let id: Element.ID
    let offset: Int
    let element: Element?
}

/// Keep lightweight membership for released pages so scrolling and focus retain their positions.
/// Only loaded pages own elements; showing a released slot reloads its original server offset.
struct LibraryPageWindow<Element: Identifiable> {
    private struct Page {
        var ids: [Element.ID]
        var elements: [Element]?
    }

    private var pages: [Int: Page] = [:]

    var slots: [LibraryPageSlot<Element>] {
        var seen = Set<Element.ID>()
        return pages.keys.sorted().flatMap { offset -> [LibraryPageSlot<Element>] in
            guard let page = pages[offset] else { return [] }
            return page.ids.enumerated().compactMap { index, id in
                guard seen.insert(id).inserted else { return nil }
                return LibraryPageSlot(id: id, offset: offset, element: page.elements?[index])
            }
        }
    }

    func isLoaded(offset: Int) -> Bool {
        pages[offset]?.elements != nil
    }

    mutating func store(_ elements: [Element], at offset: Int) {
        guard !elements.isEmpty else {
            pages.removeValue(forKey: offset)
            return
        }
        pages[offset] = Page(ids: elements.map(\.id), elements: elements)
    }

    @discardableResult
    mutating func retain(around offset: Int, visibleOffsets: Set<Int>, limit: Int) -> Bool {
        let candidates = pages.keys.filter { isLoaded(offset: $0) }.sorted {
            let lhsDistance = abs($0 - offset)
            let rhsDistance = abs($1 - offset)
            return lhsDistance == rhsDistance ? $0 < $1 : lhsDistance < rhsDistance
        }
        var retained = visibleOffsets.intersection(candidates)
        if isLoaded(offset: offset) {
            retained.insert(offset)
        }
        for candidate in candidates where retained.count < max(limit, 1) {
            retained.insert(candidate)
        }
        let evicted = candidates.filter { !retained.contains($0) }
        for key in evicted {
            pages[key]?.elements = nil
        }
        return !evicted.isEmpty
    }

    mutating func remove(ids: Set<Element.ID>) {
        for offset in pages.keys {
            pages[offset]?.ids.removeAll { ids.contains($0) }
            pages[offset]?.elements?.removeAll { ids.contains($0.id) }
            if pages[offset]?.ids.isEmpty == true {
                pages.removeValue(forKey: offset)
            }
        }
    }

    mutating func removeAll() {
        pages.removeAll()
    }
}
