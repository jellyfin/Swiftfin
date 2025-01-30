//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation

@inlinable
func clamp<T: Comparable>(_ x: T, min y: T, max z: T) -> T {
    min(max(x, y), z)
}

@inlinable
func round<T: BinaryFloatingPoint>(_ value: T, toNearest: T) -> T {
    round(value / toNearest) * toNearest
}

@inlinable
func round<T: BinaryInteger>(_ value: T, toNearest: T) -> T {
    T(round(Double(value), toNearest: Double(toNearest)))
}
