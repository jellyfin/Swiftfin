//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension Color {

    static let jellyfinPurple = Color(uiColor: .jellyfinPurple)

    var uiColor: UIColor {
        UIColor(self)
    }

    var overlayColor: Color {
        Color(uiColor: uiColor.overlayColor)
    }

    // TODO: Correct and add colors
    #if os(tvOS) // tvOS doesn't have these
    static let systemFill = Color(UIColor.white)
    static let secondarySystemFill = Color(UIColor.gray)
    static let tertiarySystemFill = Color(UIColor.black)
    static let lightGray = Color(UIColor.lightGray)
    #else
    static let systemFill = Color(UIColor.systemFill)
    static let systemBackground = Color(UIColor.systemBackground)
    static let secondarySystemFill = Color(UIColor.secondarySystemFill)
    static let tertiarySystemFill = Color(UIColor.tertiarySystemFill)
    #endif
}
