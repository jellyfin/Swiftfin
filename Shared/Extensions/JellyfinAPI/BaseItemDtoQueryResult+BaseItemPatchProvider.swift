//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension BaseItemDtoQueryResult: BaseItemPatchProvider {

    func patches(from object: Any, scope: ItemPatch.Scope) throws -> [ItemPatch] {
        guard let object = object as? [String: Any] else {
            throw CocoaError(.coderInvalidValue)
        }
        guard let items else { return [] }

        return try items.patches(from: object["Items"] ?? [], scope: scope)
    }
}
