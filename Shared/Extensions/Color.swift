//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension Color {

    static let jellyfinPurple = Color(red: 172 / 255, green: 92 / 255, blue: 195 / 255, opacity: 1)

    var uiColor: UIColor {
        UIColor(self)
    }

    var overlayColor: Color {
        Color(uiColor: uiColor.overlayColor)
    }

    // TODO: Correct and add colors
    #if os(tvOS) // tvOS doesn't have these
    static let systemFill = Color.white
    static let secondarySystemFill = Color.gray
    static let tertiarySystemFill = Color.black
    static let lightGray = Color(UIColor.lightGray)

    #else
    static let systemBackground = Color(UIColor.systemBackground)
    static let secondarySystemBackground = Color(UIColor.secondarySystemBackground)
    static let tertiarySystemBackground = Color(UIColor.tertiarySystemBackground)

    static let systemFill = Color(UIColor.systemFill)
    static let secondarySystemFill = Color(UIColor.secondarySystemFill)
    static let tertiarySystemFill = Color(UIColor.tertiarySystemFill)
    #endif
}
