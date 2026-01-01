//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine

class SliderContainerState<Value: BinaryFloatingPoint>: ObservableObject {

    @Published
    var isEditing: Bool
    @Published
    var isFocused: Bool
    @Published
    var value: Value

    let total: Value

    init(
        isEditing: Bool,
        isFocused: Bool,
        value: Value,
        total: Value
    ) {
        self.isEditing = isEditing
        self.isFocused = isFocused
        self.value = value
        self.total = total
    }
}
