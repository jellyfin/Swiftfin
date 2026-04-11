//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ProfileCondition {

    init(
        condition: ProfileConditionType? = nil,
        isRequired: Bool? = nil,
        property: ProfileConditionValue? = nil,
        @ArrayBuilder<String> value: () -> [String]
    ) {
        self.init(
            condition: condition,
            isRequired: isRequired,
            property: property,
            value: value().joined(separator: "|")
        )
    }
}
