//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import UIKit

extension UIApplication {

    static var appVersion: String? {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }

    static var bundleVersion: String? {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
    }

    var keyWindow: UIWindow? {
        connectedScenes
            .compactMap {
                $0 as? UIWindowScene
            }
            .flatMap(\.windows)
            .first {
                $0.isKeyWindow
            }
    }

    func setAccentColor(_ newColor: UIColor) {
        keyWindow?.tintColor = newColor
    }

    func setAppearance(_ newAppearance: UIUserInterfaceStyle) {
        keyWindow?.overrideUserInterfaceStyle = newAppearance
    }

    #if os(iOS)
    func setNavigationBackButtonAccentColor(_ newColor: UIColor) {
        let config = UIImage.SymbolConfiguration(paletteColors: [newColor.overlayColor, newColor])
        let backButtonBackgroundImage = UIImage(systemName: "chevron.backward.circle.fill", withConfiguration: config)
        let barAppearance = UINavigationBar.appearance()
        barAppearance.backIndicatorImage = backButtonBackgroundImage
        barAppearance.backIndicatorTransitionMaskImage = backButtonBackgroundImage
    }
    #endif
}
