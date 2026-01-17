//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct WithDefaults<Content: View, Value: _DefaultsSerializable>: View {

    @Default<Value>
    private var value: Value

    private let content: (Value) -> Content

    init(
        _ key: Defaults.Key<Value>,
        @ViewBuilder content: @escaping (Value) -> Content
    ) {
        self._value = Default(key)
        self.content = content
    }

    var body: some View {
        content(value)
    }
}
