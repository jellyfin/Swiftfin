//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension Binding {

    func map<V>(getter: @escaping (Value) -> V, setter: @escaping (V) -> Value) -> Binding<V> {
        Binding<V>(
            get: { getter(wrappedValue) },
            set: { wrappedValue = setter($0) }
        )
    }
}
