//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

protocol LibraryParent: Displayable, Identifiable<String?> {

    // Only called `libraryType` because `BaseItemPerson` has
    // a different `type` property. However, people should have
    // different views so this can be renamed when they do, or
    // this protocol to be removed entirely and replace just with
    // a concrete `BaseItemDto`
    //
    // edit: studios also implement `LibraryParent` - reconsider above comment
    var libraryType: BaseItemKind? { get }
}
