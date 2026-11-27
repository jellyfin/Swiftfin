//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension Binding {

    func clamp(min: Value, max: Value) -> Binding<Value> where Value: Comparable & Hashable {
        self[dynamicMember: \.[bindingClampedMin: min, max: max]]
    }

    func coalesce<T: Hashable>(_ defaultValue: T) -> Binding<T> where Value == T? {
        self[dynamicMember: \.[bindingDefault: defaultValue]]
    }

    func map<V>(getter: @escaping (Value) -> V, setter: @escaping (V) -> Value) -> Binding<V> {
        Binding<V>(
            get: { getter(wrappedValue) },
            set: { newValue, transaction in
                self.transaction(transaction).wrappedValue = setter(newValue)
            }
        )
        .transaction(transaction)
    }

    func min(_ minValue: Value) -> Binding<Value> where Value: Comparable & Hashable {
        self[dynamicMember: \.[bindingMinimum: minValue]]
    }

    func negate() -> Binding<Bool> where Value == Bool {
        self[dynamicMember: \.bindingNegated]
    }
}

extension Binding where Value: RangeReplaceableCollection, Value.Element: Hashable {

    func contains(_ element: Value.Element) -> Binding<Bool> {
        self[dynamicMember: \.[bindingContains: element]]
    }
}

extension Binding where Value: SetAlgebra, Value.Element: Hashable {

    func contains(_ element: Value.Element) -> Binding<Bool> {
        self[dynamicMember: \.[bindingContains: element]]
    }
}

private extension Comparable where Self: Hashable {

    subscript(bindingClampedMin minimum: Self, max maximum: Self) -> Self {
        get { Swift.min(Swift.max(self, minimum), maximum) }
        set { self = Swift.min(Swift.max(newValue, minimum), maximum) }
    }

    subscript(bindingMinimum minimum: Self) -> Self {
        get { Swift.max(self, minimum) }
        set { self = Swift.max(newValue, minimum) }
    }
}

private extension Optional where Wrapped: Hashable {

    subscript(bindingDefault defaultValue: Wrapped) -> Wrapped {
        get { self ?? defaultValue }
        set { self = newValue }
    }
}

private extension Bool {

    var bindingNegated: Bool {
        get { !self }
        set { self = !newValue }
    }
}

private extension RangeReplaceableCollection where Element: Hashable {

    subscript(bindingContains element: Element) -> Bool {
        get { contains(element) }
        set {
            if newValue {
                if !contains(element) {
                    append(element)
                }
            } else {
                removeAll { $0 == element }
            }
        }
    }
}

private extension SetAlgebra where Element: Hashable {

    subscript(bindingContains element: Element) -> Bool {
        get { contains(element) }
        set {
            if newValue {
                insert(element)
            } else {
                remove(element)
            }
        }
    }
}
