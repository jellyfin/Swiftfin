//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import Get
import JellyfinAPI

extension ItemPatch {

    static func sessionItems(from response: Response<[SessionInfoDto]>) throws -> [ItemPatch] {
        let objects = try JSONSerialization.jsonObject(with: response.data) as? [[String: Any]] ?? []
        guard objects.count == response.value.count else { throw CocoaError(.coderInvalidValue) }
        return zip(response.value, objects).compactMap { session, object in
            guard let item = session.nowPlayingItem,
                  let fields = object["NowPlayingItem"] as? [String: Any] else { return nil }
            return ItemPatch(value: item.withoutUserData, object: removingUserData(from: fields))
        }
    }

    private static func removingUserData(from object: [String: Any]) -> [String: Any] {
        var fields = object
        fields.removeValue(forKey: "UserData")
        if let program = fields["CurrentProgram"] as? [String: Any] {
            fields["CurrentProgram"] = removingUserData(from: program)
        }
        return fields
    }

    static func items(from response: Response<BaseItemDtoQueryResult>) throws -> [ItemPatch] {
        try items(response.value.items ?? [], data: response.data)
    }

    static func items(from response: Response<[BaseItemDto]>) throws -> [ItemPatch] {
        try items(response.value, data: response.data)
    }

    private static func items(_ values: [BaseItemDto], data: Data) throws -> [ItemPatch] {
        let json = try JSONSerialization.jsonObject(with: data)
        let objects = (json as? [[String: Any]]) ?? (json as? [String: Any])?["Items"] as? [[String: Any]] ?? []
        guard objects.count == values.count else { throw CocoaError(.coderInvalidValue) }
        return zip(values, objects).map { ItemPatch(value: $0, object: $1) }
    }

    init(response: Response<BaseItemDto>) throws {
        let object = try JSONSerialization.jsonObject(with: response.data) as? [String: Any] ?? [:]
        self.init(value: response.value, object: object)
    }
}

extension BaseItemDto {
    var withoutUserData: BaseItemDto {
        var value = self
        value.userData = nil
        value.currentProgram = currentProgram?.withoutUserData
        return value
    }
}
