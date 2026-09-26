//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftfinMacros
import SwiftUI

extension UIInterfaceOrientationMask: CustomDebugStringConvertible {
    public var debugDescription: String {
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
@OptionSet<Int>
public struct UIInterfaceOrientationMask {

    private enum Options: Int {
        case portrait = 1
        case landscapeLeft = 4
        case landscapeRight = 3
        case portraitUpsideDown = 2
    }

    public static var landscape: Self {
        [.landscapeLeft, .landscapeRight]
    }

    public static var all: Self {
        [.portrait, .landscapeLeft, .landscapeRight, .portraitUpsideDown]
    }

    public static var allButUpsideDown: Self {
        [.portrait, .landscapeLeft, .landscapeRight]
    }
}
#endif
