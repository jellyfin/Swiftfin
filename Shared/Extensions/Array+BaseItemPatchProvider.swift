//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

extension Array: BaseItemPatchProvider where Element: BaseItemPatchProvider {

    func patches(from object: Any, scope: ItemPatch.Scope) throws -> [ItemPatch] {
        // DTOs and raw JSON must stay aligned to preserve field presence
        guard let objects = object as? [Any], objects.count == count else {
            throw CocoaError(.coderInvalidValue)
        }

        return try zip(self, objects).flatMap { value, object in
            try value.patches(from: object, scope: scope)
        }
    }
}
