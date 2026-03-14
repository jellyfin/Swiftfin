//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

@propertyWrapper
struct BoxedPublished<Value>: DynamicProperty {

    @StateObject
    var storage: PublishedBox<Value>

    init(wrappedValue: Value) {
        self._storage = StateObject(wrappedValue: PublishedBox(initialValue: wrappedValue))
    }

    var wrappedValue: Value {
        get { storage.value }
        nonmutating set { storage.value = newValue }
    }

    var projectedValue: Published<Value>.Publisher {
        storage.$value
    }

    var box: PublishedBox<Value> {
        storage
    }
}
