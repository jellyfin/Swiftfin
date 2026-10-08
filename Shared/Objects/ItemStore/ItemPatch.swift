//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

/// Carries a decoded DTO and the field names selected for merging.
struct ItemPatch {

    /// Controls whether omitted fields are kept, clear metadata, or clear the full item.
    enum Scope {

        case partial
        case metadataSnapshot
        case fullItem
    }

    let value: BaseItemDto
    let fields: Set<String>
    let userDataFields: Set<String>
    let program: [String: Any]?
    let scope: Scope

    /// Builds a patch when field presence is already known, such as a user-data update.
    init(
        value: BaseItemDto,
        fields: Set<String>,
        userDataFields: Set<String> = [],
        program: [String: Any]? = nil,
        scope: Scope = .partial
    ) {
        self.value = value
        self.fields = fields
        self.userDataFields = userDataFields
        self.program = program
        self.scope = scope
    }

    /// Pairs a decoded DTO with the field names in its source object.
    static func decoded(_ value: BaseItemDto, object: [String: Any], scope: Scope = .partial) -> ItemPatch {
        ItemPatch(
            value: value,
            fields: Set(object.keys),
            userDataFields: Set((object["UserData"] as? [String: Any] ?? [:]).keys),
            program: object["CurrentProgram"] as? [String: Any],
            scope: scope
        )
    }

    /// Uses encoded fields when a local snapshot has no raw response.
    static func snapshot(_ value: BaseItemDto, scope: Scope = .partial) throws -> ItemPatch {
        try decoded(value, object: JSONSerialization.encode(value), scope: scope)
    }
}
