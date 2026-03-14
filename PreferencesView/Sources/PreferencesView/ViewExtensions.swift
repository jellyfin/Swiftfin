//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

public extension UIInterfaceOrientationMask {
    var displayTitle: String {
        switch self {
        case .all: "All Orientations"
        case .allButUpsideDown: "All But Upside Down"
        case .portrait: "Portrait"
        case .portraitUpsideDown: "Portrait Upside Down"
        case .landscape: "Landscape"
        case .landscapeLeft: "Landscape Left"
        case .landscapeRight: "Landscape Right"
        default: "Unknown"
        }
    }
}

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
    #endif

    #if os(tvOS)
    func pressCommands(@PressCommandsBuilder _ commands: @escaping () -> [PressCommandAction]) -> some View {
        preference(key: PressCommandsPreferenceKey.self, value: commands())
    }
    #endif

    /// - Important: This does nothing on tvOS.
    func supportedOrientations(_ supportedOrientations: UIInterfaceOrientationMask) -> some View {
        #if os(tvOS)
        self
        #else
        preference(key: SupportedOrientationsPreferenceKey.self, value: supportedOrientations)
        #endif
    }
}

#if os(tvOS)
public struct UIInterfaceOrientationMask: OptionSet {

    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let portrait = UIInterfaceOrientationMask(rawValue: 1 << 1)
    public static let landscapeLeft = UIInterfaceOrientationMask(rawValue: 1 << 4)
    public static let landscapeRight = UIInterfaceOrientationMask(rawValue: 1 << 3)
    public static let portraitUpsideDown = UIInterfaceOrientationMask(rawValue: 1 << 2)
    public static let landscape: UIInterfaceOrientationMask = [.landscapeLeft, .landscapeRight]
    public static let all: UIInterfaceOrientationMask = [.portrait, .landscapeLeft, .landscapeRight, .portraitUpsideDown]
    public static let allButUpsideDown: UIInterfaceOrientationMask = [.portrait, .landscapeLeft, .landscapeRight]
}
#endif
