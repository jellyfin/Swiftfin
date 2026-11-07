//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import FactoryKit
import Foundation
import JellyfinAPI

typealias SharedUser = SharedElement<UserRecord>

extension UserRecord: SharedHandle {

    static func resolve(_ value: UserDto) -> UserRecord {
        let store = Container.shared.currentUserSession()?.users

        // Values without a session or usable ID are only for presentation
        return (try? store?.record(for: value)) ?? UserRecord(
            id: value.id ?? UUID().uuidString,
            value: value
        )
    }

    var snapshot: UserDto {
        value ?? UserDto(id: id)
    }
}
