//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

struct TypeKeyedDictionary<Value> {

    private var elements: [(key: Any.Type, value: Value)] = []

    subscript(type: (some Any).Type) -> Value? {
        get {
            elements.first { $0.key == type }?.value
        }
        set {
            if let index = elements.firstIndex(where: { $0.key == type }) {
                if let newValue {
                    elements[index].value = newValue
                } else {
                    elements.remove(at: index)
                }
            } else if let newValue {
                elements.append((key: type, value: newValue))
            }
        }
    }

    func inserting(type: (some Any).Type, value: Value?) -> Self {
        var copy = self
        copy[type] = value
        return copy
    }
}

extension TypeKeyedDictionary: Equatable where Value: Equatable {

    static func == (lhs: TypeKeyedDictionary<Value>, rhs: TypeKeyedDictionary<Value>) -> Bool {
        guard lhs.elements.count == rhs.elements.count else { return false }

        return lhs.elements.allSatisfy { key, value in
            rhs.elements.first { $0.key == key }?.value == value
        }
    }
}
