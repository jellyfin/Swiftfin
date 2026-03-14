//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

@_exported import CasePaths
@_exported import StatefulMacros

@inlinable
func clamp<T: Comparable>(_ x: T, min y: T, max z: T) -> T {
    min(max(x, y), z)
}

@inlinable
func copy<P, Value>(_ p: P, modifying keyPath: WritableKeyPath<P, Value>, to newValue: Value) -> P {
    var copy = p
    copy[keyPath: keyPath] = newValue
    return copy
}

@inlinable
func round<T: BinaryFloatingPoint>(_ value: T, toNearest: T) -> T {
    round(value / toNearest) * toNearest
}

@inlinable
func round<T: BinaryInteger>(_ value: T, toNearest: T) -> T {
    T(round(Double(value), toNearest: Double(toNearest)))
}

@inlinable
func with<V>(_ value: V, modify: @escaping (inout V) -> Void) -> V {
    var value = value
    modify(&value)
    return value
}
