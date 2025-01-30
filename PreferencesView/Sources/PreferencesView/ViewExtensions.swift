//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

public extension View {

    #if os(iOS)
    func keyCommands(@KeyCommandsBuilder _ commands: @escaping () -> [KeyCommandAction]) -> some View {
        preference(key: KeyCommandsPreferenceKey.self, value: commands())
    }

    func preferredScreenEdgesDeferringSystemGestures(_ edges: UIRectEdge) -> some View {
        preference(key: PreferredScreenEdgesDeferringSystemGesturesPreferenceKey.self, value: edges)
    }

    func prefersHomeIndicatorAutoHidden(_ hidden: Bool) -> some View {
        preference(key: PrefersHomeIndicatorAutoHiddenPreferenceKey.self, value: hidden)
    }

    func supportedOrientations(_ supportedOrientations: UIInterfaceOrientationMask) -> some View {
        preference(key: SupportedOrientationsPreferenceKey.self, value: supportedOrientations)
    }
    #endif

    #if os(tvOS)
    func pressCommands(@PressCommandsBuilder _ commands: @escaping () -> [PressCommandAction]) -> some View {
        preference(key: PressCommandsPreferenceKey.self, value: commands())
    }
    #endif
}
