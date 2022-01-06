//
 /* 
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import SwiftUI

extension Color {

    static let jellyfinPurple = Color(uiColor: .jellyfinPurple)

    #if os(tvOS) // tvOS doesn't have these
    public static let systemFill = Color(UIColor.white)
    public static let secondarySystemFill = Color(UIColor.gray)
    public static let tertiarySystemFill = Color(UIColor.black)
    public static let lightGray = Color(UIColor.lightGray)
    #else
    public static let systemFill = Color(UIColor.systemFill)
    public static let secondarySystemFill = Color(UIColor.secondarySystemBackground)
    public static let tertiarySystemFill = Color(UIColor.tertiarySystemBackground)
    #endif
}

extension UIColor {
    static let jellyfinPurple = UIColor(red: 172 / 255, green: 92 / 255, blue: 195 / 255, alpha: 1)
}
