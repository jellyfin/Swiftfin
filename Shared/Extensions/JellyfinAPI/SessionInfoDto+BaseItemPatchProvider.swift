//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension SessionInfoDto: BaseItemPatchProvider {

    func patches(from object: Any, scope: ItemPatch.Scope) throws -> [ItemPatch] {
        guard let object = object as? [String: Any] else {
            throw CocoaError(.coderInvalidValue)
        }
        guard let nowPlayingItem else { return [] }
        guard let fields = object["NowPlayingItem"] as? [String: Any] else {
            throw CocoaError(.coderInvalidValue)
        }

        // Other sessions' user data does not belong to the current signed-in user.
        return [ItemPatch.decoded(
            nowPlayingItem.withoutUserData,
            object: removingUserData(from: fields),
            scope: scope
        )]
    }

    private func removingUserData(from object: [String: Any]) -> [String: Any] {
        var fields = object
        fields.removeValue(forKey: "UserData")

        if let program = fields["CurrentProgram"] as? [String: Any] {
            fields["CurrentProgram"] = removingUserData(from: program)
        }

        return fields
    }
}
