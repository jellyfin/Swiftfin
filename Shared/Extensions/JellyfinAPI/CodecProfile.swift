//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension CodecProfile {

    init(
        codec: String? = nil,
        container: String? = nil,
        type: CodecType? = nil,
        @ArrayBuilder<ProfileCondition> applyConditions: () -> [ProfileCondition] = { [] },
        @ArrayBuilder<ProfileCondition> conditions: () -> [ProfileCondition] = { [] }
    ) {
        let applyConditions = applyConditions()
        let conditions = conditions()

        self.init(
            applyConditions: applyConditions.isEmpty ? nil : applyConditions,
            codec: codec,
            conditions: conditions.isEmpty ? nil : conditions,
            container: container,
            type: type
        )
    }
}
