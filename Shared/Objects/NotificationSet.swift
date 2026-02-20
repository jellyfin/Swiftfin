//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

/// A container for `Notifications.Key`.
struct NotificationSet {

    private var names: Set<String> = []

    func contains(_ key: Notifications.Key<some Any>) -> Bool {
        names.contains(key.name.rawValue)
    }

    mutating func insert(_ key: Notifications.Key<some Any>) {
        names.insert(key.name.rawValue)
    }

    mutating func remove(_ key: Notifications.Key<some Any>) {
        names.remove(key.name.rawValue)
    }
}
