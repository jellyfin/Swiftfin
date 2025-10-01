//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

struct TypeKeyedDictionary<Value> {

    private var elements: [(key: Any.Type, value: Value)]

    init() {
        self.elements = []
    }

    subscript<T>(type: T.Type) -> Value? {
        get {
            elements.first(where: { $0.key == type })?.value
        }
        set {
            if let index = elements.firstIndex(where: { $0.key == type }) {
                if let newValue = newValue {
                    elements[index].value = newValue
                } else {
                    elements.remove(at: index)
                }
            } else if let newValue = newValue {
                elements.append((key: type, value: newValue))
            }
        }
    }

    // TODO: rename `withSetting`
    func withInsert<T>(type: T.Type, value: Value?) -> Self {
        if let value {
            var copy = self
            copy[type] = value
            return copy
        } else {
            var copy = self
            copy[type] = nil
            return copy
        }
    }
}
