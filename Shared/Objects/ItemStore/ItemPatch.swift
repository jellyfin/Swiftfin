//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

/// Carries a decoded DTO and the field names selected for merging
struct ItemPatch {

    /// Defines field update behavior
    enum Scope {

        /// Preserves omitted fields
        case partial
        /// Replaces metadata while preserving user data and the current program
        case metadataSnapshot
        /// Represents all valid data, including omitted fields
        case fullItem
    }

    let value: BaseItemDto
    let fields: Set<String>
    let userDataFields: Set<String>
    let program: [String: Any]?
    let scope: Scope

    /// Builds a patch when field presence is already known, such as a user-data update
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

    /// Preserves field presence so explicit nulls can clear stored values
    static func decoded(
        _ value: BaseItemDto,
        object: [String: Any],
        scope: Scope = .partial
    ) -> ItemPatch {
        ItemPatch(
            value: value,
            fields: Set(object.keys),
            userDataFields: Set((object["UserData"] as? [String: Any] ?? [:]).keys),
            program: object["CurrentProgram"] as? [String: Any],
            scope: scope
        )
    }

    /// Builds a patch from the fields included by DTO encoding
    static func snapshot(
        _ value: BaseItemDto,
        scope: Scope = .partial
    ) throws -> ItemPatch {
        try decoded(
            value,
            object: JSONSerialization.encode(value),
            scope: scope
        )
    }
}
