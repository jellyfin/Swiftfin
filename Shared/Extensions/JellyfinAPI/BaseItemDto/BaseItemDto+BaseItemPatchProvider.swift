//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension BaseItemDto: BaseItemPatchProvider {

    func patches(from object: Any, scope: ItemPatch.Scope) throws -> CollectionOfOne<ItemPatch> {
        guard let object = object as? [String: Any] else {
            throw CocoaError(.coderInvalidValue)
        }

        return .init(ItemPatch.decoded(self, object: object, scope: scope))
    }
}
