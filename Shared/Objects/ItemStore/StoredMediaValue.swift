//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

/// Generic presentation components retain media references while still accepting non-media values.
@MainActor
@propertyWrapper
struct StoredMediaValue<Value> {
    private enum Storage {
        case item(StoredItem)
        case value(Value)
    }

    private var storage: Storage

    init(wrappedValue: Value) {
        if let item = wrappedValue as? BaseItemDto {
            storage = .item(StoredItem(wrappedValue: item))
        } else {
            storage = .value(wrappedValue)
        }
    }

    var wrappedValue: Value {
        get {
            switch storage {
            case let .item(item): item.wrappedValue as! Value
            case let .value(value): value
            }
        }
        set { self = StoredMediaValue(wrappedValue: newValue) }
    }
}
