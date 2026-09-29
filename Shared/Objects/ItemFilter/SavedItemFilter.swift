//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

struct SavedItemFilter: Displayable, Hashable, Identifiable, Storable {

    private(set) var id: String = UUID().uuidString
    let libraryID: String?
    let parentID: String?
    let parentType: BaseItemKind?
    var name: String
    var filters: ItemFilterCollection
    var grouping: BaseItemDto.Grouping?
    var posterDisplayType: PosterDisplayType?

    var displayTitle: String {
        name
    }
}
