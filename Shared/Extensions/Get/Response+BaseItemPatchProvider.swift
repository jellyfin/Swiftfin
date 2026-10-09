//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import Get

extension Response where T: BaseItemPatchProvider {

    func patches(scope: ItemPatch.Scope = .partial) throws -> T.Patches {
        let object = try JSONSerialization.jsonObject(with: data)
        return try value.patches(from: object, scope: scope)
    }
}
