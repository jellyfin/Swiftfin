//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// MARK: - Bruno brand typography

//
// Display = Oswald (the Knockout brand stand-in), uppercase, used for the wordmark,
// hero/section titles and tile labels. Body = Inter. Both ship as variable .ttf in
// `Swiftfin tvOS/Resources/Fonts/` and are registered via `UIAppFonts`. `Font.custom`
// silently falls back to the system font if a family is unavailable, so these helpers
// are safe even if the fonts fail to register.
extension Font {

    private enum BrunoFamily {
        static let display = "Oswald"
        static let body = "Inter"
    }

    /// Oswald display face. Use for the wordmark, hero/section titles, tiles.
    static func brunoDisplay(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .custom(BrunoFamily.display, size: size)
            .weight(weight)
    }

    /// Inter body face. Use for blurbs, meta lines, captions.
    static func brunoBody(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom(BrunoFamily.body, size: size)
            .weight(weight)
    }
}
