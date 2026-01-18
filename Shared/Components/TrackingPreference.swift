//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct TrackingPreference<Content: View, Key: PreferenceKey>: View where Key.Value: Equatable {

    @State
    private var currentValue = Key.defaultValue

    private let content: (Key.Value) -> Content
    private let key: Key.Type

    init(
        key: Key.Type,
        @ViewBuilder content: @escaping (Key.Value) -> Content
    ) {
        self.content = content
        self.key = key
    }

    var body: some View {
        content(currentValue)
            .onPreferenceChange(key) { newValue in
                currentValue = newValue
            }
    }
}
