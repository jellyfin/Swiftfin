//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Foundation

extension Equatable {

    func random(in range: Range<Int>) -> [Self] {
        Array(repeating: self, count: Int.random(in: range))
    }

    func repeating(count: Int) -> [Self] {
        Array(repeating: self, count: count)
    }

    func mutating<Value>(_ keyPath: WritableKeyPath<Self, Value>, with newValue: Value) -> Self {
        var copy = self
        copy[keyPath: keyPath] = newValue
        return copy
    }
}
