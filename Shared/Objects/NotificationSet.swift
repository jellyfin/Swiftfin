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

    func contains<P>(_ key: Notifications.Key<P>) -> Bool {
        names.contains(key.name.rawValue)
    }

    mutating func insert<P>(_ key: Notifications.Key<P>) {
        names.insert(key.name.rawValue)
    }

    mutating func remove<P>(_ key: Notifications.Key<P>) {
        names.remove(key.name.rawValue)
    }
}
