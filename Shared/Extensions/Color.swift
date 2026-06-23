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

    /// Bruno brand palette (Diplomacy → Bruno dark theme). See prototype/design_handoff_bruno/README.md.
    enum bruno {
        static let page = Color(hex: "14120F") // app background (warm umber)
        static let surface = Color(hex: "1C1A16") // card base before art loads
        static let diplomacyDark = Color(hex: "302D26")
        static let diplomacyBrown = Color(hex: "4E433D") // elevated warm surface / portrait cards
        static let fg = Color(hex: "F2F1F0") // primary text
        static let fgMuted = Color(hex: "CFC9BF") // body / blurbs
        static let fgSubtle = Color(hex: "9B958C") // meta, idle nav
        static let accent = Color(hex: "A1CCE0") // focus ring, progress, ★, active states (Apolla sky)
        static let accentAlt = Color(hex: "849396") // Diplomacy blue
        static let sand = Color(hex: "D9D7C2") // tile text / warm highlights
        static let critic = Color(hex: "CC4444") // critic-score dot
    }

    var uiColor: UIColor {
        UIColor(self)
    }

    var overlayColor: Color {
        Color(uiColor: uiColor.overlayColor)
    }

    // TODO: Correct and add colors
    #if os(tvOS)
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

extension Color {

    struct RGBA {

        enum Component {
            case red
            case green
            case blue
            case alpha
        }

        var red: CGFloat
        var green: CGFloat
        var blue: CGFloat
        var alpha: CGFloat
    }

    var rgbaComponents: RGBA {
        get {
            var r: CGFloat = 0
            var g: CGFloat = 0
            var b: CGFloat = 0
            var a: CGFloat = 0

            uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)

            return RGBA(
                red: r,
                green: g,
                blue: b,
                alpha: a
            )
        }
        mutating set {
            self = Color(
                red: newValue.red,
                green: newValue.green,
                blue: newValue.blue,
                opacity: newValue.alpha
            )
        }
    }

    func with(rgba: WritableKeyPath<RGBA, CGFloat>, value: CGFloat) -> Color {
        var components = rgbaComponents
        components[keyPath: rgba] = value
        return Color(
            red: components.red,
            green: components.green,
            blue: components.blue,
            opacity: components.alpha
        )
    }

    init(hex: String) {
        let s = hex.hasPrefix("#") ? hex.dropFirst() : Substring(hex)
        let x = UInt64(s, radix: 16) ?? 0
        self.init(
            .sRGB,
            red: Double((x >> 16) & 255) / 255,
            green: Double((x >> 8) & 255) / 255,
            blue: Double(x & 255) / 255,
            opacity: s.count > 6 ? Double((x >> 24) & 255) / 255 : 1
        )
    }

    var hexString: String {
        let components = rgbaComponents
        let r = Int(components.red * 255)
        let g = Int(components.green * 255)
        let b = Int(components.blue * 255)
        let a = Int(components.alpha * 255)

        if a < 255 {
            return String(format: "%02X%02X%02X%02X", r, g, b, a)
        } else {
            return String(format: "%02X%02X%02X", r, g, b)
        }
    }
}
