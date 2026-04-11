//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension Binding {

    func clamp(min: Value, max: Value) -> Binding<Value> where Value: Comparable {
        Binding<Value>(
            get: { Swift.min(Swift.max(wrappedValue, min), max) },
            set: { wrappedValue = Swift.min(Swift.max($0, min), max) }
        )
    }

    func coalesce<T>(_ defaultValue: T) -> Binding<T> where Value == T? {
        Binding<T>(
            get: { wrappedValue ?? defaultValue },
            set: { wrappedValue = $0 }
        )
    }

    func contains<E: Equatable>(_ value: E) -> Binding<Bool> where Value == [E] {
        Binding<Bool>(
            get: { wrappedValue.contains(value) },
            set: { shouldBeContained in
                if shouldBeContained {
                    wrappedValue.append(value)
                } else {
                    wrappedValue.removeAll { $0 == value }
                }
            }
        )
    }

    func map<V>(getter: @escaping (Value) -> V, setter: @escaping (V) -> Value) -> Binding<V> {
        Binding<V>(
            get: { getter(wrappedValue) },
            set: { wrappedValue = setter($0) }
        )
    }

    func min(_ minValue: Value) -> Binding<Value> where Value: Comparable {
        Binding<Value>(
            get: { Swift.max(wrappedValue, minValue) },
            set: { wrappedValue = Swift.max($0, minValue) }
        )
    }

    func negate() -> Binding<Bool> where Value == Bool {
        map(getter: { !$0 }, setter: { $0 })
    }
}

extension Binding where Value: RangeReplaceableCollection, Value.Element: Equatable {

    func contains(_ element: Value.Element) -> Binding<Bool> {
        Binding<Bool>(
            get: { wrappedValue.contains(element) },
            set: { newValue in
                if newValue {
                    if !wrappedValue.contains(element) {
                        wrappedValue.append(element)
                    }
                } else {
                    wrappedValue.removeAll { $0 == element }
                }
            }
        )
    }
}
