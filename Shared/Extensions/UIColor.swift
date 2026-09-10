//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

#if canImport(UIKit)
import UIKit
#elseif os(macOS)
import AppKit
#endif

extension UIColor {
    var overlayColor: UIColor {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        #if os(macOS)
        guard let color = usingColorSpace(.deviceRGB) else { return .white }
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #else
        guard getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return .white }
        #endif

        let brightness = ((red * 299) + (green * 587) + (blue * 114)) / 1000

        return brightness < 0.5 ? .white : .black
    }
}
