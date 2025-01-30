//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

#if os(iOS)
struct KeyCommandsPreferenceKey: PreferenceKey {

    static var defaultValue: [KeyCommandAction] = []

    static func reduce(value: inout [KeyCommandAction], nextValue: () -> [KeyCommandAction]) {
        value.append(contentsOf: nextValue())
    }
}

struct PreferredScreenEdgesDeferringSystemGesturesPreferenceKey: PreferenceKey {

    static var defaultValue: UIRectEdge = [.left, .right]

    static func reduce(value: inout UIRectEdge, nextValue: () -> UIRectEdge) {}
}

struct PrefersHomeIndicatorAutoHiddenPreferenceKey: PreferenceKey {

    static var defaultValue: Bool = false

    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = nextValue() || value
    }
}

struct SupportedOrientationsPreferenceKey: PreferenceKey {

    static var defaultValue: UIInterfaceOrientationMask = .allButUpsideDown

    static func reduce(value: inout UIInterfaceOrientationMask, nextValue: () -> UIInterfaceOrientationMask) {
        value = nextValue()
    }
}
#endif

#if os(tvOS)
struct PressCommandsPreferenceKey: PreferenceKey {

    static var defaultValue: [PressCommandAction] = []

    static func reduce(value: inout [PressCommandAction], nextValue: () -> [PressCommandAction]) {
        value.append(contentsOf: nextValue())
    }
}
#endif
