//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

protocol BaseItemPatchProvider: Encodable {

    associatedtype Patches: RandomAccessCollection<ItemPatch>

    func patches(from object: Any, scope: ItemPatch.Scope) throws -> Patches
}

extension BaseItemPatchProvider {

    /// Provide a patch from the current value
    func patches(scope: ItemPatch.Scope = .partial) throws -> Patches {
        let data = try JSONEncoder().encode(self)
        let object = try JSONSerialization.jsonObject(with: data)
        return try patches(from: object, scope: scope)
    }
}
