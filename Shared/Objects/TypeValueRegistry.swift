//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

// TODO: remove

struct TypeValueRegistry<Value> {

    private var registry: [(key: Any.Type, value: Value)] = []

    func getvalue<T>(for otherType: T.Type) -> Value? {
        registry.first(where: { $0.key == otherType })?.value
    }

    func insertOrReplace(_ value: Value, for type: Any.Type) -> Self {
        var newRegistry = self
        if let existing = newRegistry.registry.firstIndex(where: { $0.key == type }) {
            newRegistry.registry[existing].value = value
        } else {
            newRegistry.registry.append((key: type, value: value))
        }
        return newRegistry
    }
}
