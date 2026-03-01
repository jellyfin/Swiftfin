//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

protocol _LibraryParent: Displayable {

    associatedtype Grouping: LibraryGrouping = Empty

    var groupings: (defaultSelection: Grouping, elements: [Grouping])? { get }
    var libraryID: String { get }
}

extension _LibraryParent where Grouping == Empty {
    var groupings: (defaultSelection: Grouping, elements: [Grouping])? {
        nil
    }
}

struct _TitledLibraryParent: _LibraryParent {

    let displayTitle: String
    let libraryID: String
}
