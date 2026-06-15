//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct ContentGroupParentOption: OptionSet {

    let rawValue: Int

    static let ignoreTopSafeArea = Self(rawValue: 1 << 0)
    static let useOffsetNavigationBar = Self(rawValue: 1 << 1)
}

struct ContentGroupCustomizationKey: PreferenceKey {

    static var defaultValue: ContentGroupParentOption = []

    static func reduce(
        value: inout ContentGroupParentOption,
        nextValue: () -> ContentGroupParentOption
    ) {
        value.formUnion(nextValue())
    }
}
