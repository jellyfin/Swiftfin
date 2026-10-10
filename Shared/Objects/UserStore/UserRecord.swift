//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import Observation

@MainActor
@Observable
final class UserRecord: Identifiable {

    nonisolated let id: String
    private(set) var value: UserDto?

    @ObservationIgnored
    private var revision: UInt64 = 0

    init(id: String, value: UserDto?) {
        self.id = id
        self.value = value
    }

    @discardableResult
    func replace(with value: UserDto, revision: UInt64) -> Bool {
        guard revision >= self.revision else { return false }

        self.revision = revision

        if self.value != value {
            self.value = value
        }

        return true
    }

    func invalidate() {
        value = nil
    }
}
