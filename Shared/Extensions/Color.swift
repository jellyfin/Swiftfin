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

    func isEqual(to other: Color, tolerance: CGFloat = 0.001) -> Bool {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0

        UIColor(self).getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        UIColor(other).getRed(&r2, green: &g2, blue: &b2, alpha: &a2)

        return abs(r1 - r2) < tolerance &&
            abs(g1 - g2) < tolerance &&
            abs(b1 - b2) < tolerance &&
            abs(a1 - a2) < tolerance
    }
}

extension Color {

    init?(hex: String) {
        let hex = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex

        guard hex.count == 6 || hex.count == 8 else { return nil }
        guard let value = UInt32(hex, radix: 16) else { return nil }

        let red: CGFloat
        let green: CGFloat
        let blue: CGFloat
        let opacity: CGFloat

        if hex.count == 8 {
            red = CGFloat((value & 0xFF00_0000) >> 24) / 255
            green = CGFloat((value & 0x00FF_0000) >> 16) / 255
            blue = CGFloat((value & 0x0000_FF00) >> 8) / 255
            opacity = CGFloat(value & 0x0000_00FF) / 255
        } else {
            red = CGFloat((value & 0xFF0000) >> 16) / 255
            green = CGFloat((value & 0x00FF00) >> 8) / 255
            blue = CGFloat(value & 0x0000FF) / 255
            opacity = 1
        }

        self.init(red: red, green: green, blue: blue, opacity: opacity)
    }

    func hexString(includeOpacity: Bool = false) -> String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        let format = includeOpacity ? "#%02X%02X%02X%02X" : "#%02X%02X%02X"

        let components = includeOpacity
            ? [Int(255 * red), Int(255 * green), Int(255 * blue), Int(255 * alpha)]
            : [Int(255 * red), Int(255 * green), Int(255 * blue)]

        return String(format: format, arguments: components.map { $0 as CVarArg })
    }
}
