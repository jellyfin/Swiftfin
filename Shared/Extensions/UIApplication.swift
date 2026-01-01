//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
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

    // TODO: change to all windows?
    func setAccentColor(_ newColor: UIColor) {
        keyWindow?.tintColor = newColor
    }

    func setAppearance(_ newAppearance: UIUserInterfaceStyle) {
        guard let keyWindow else { return }

        UIView.transition(with: keyWindow, duration: 0.2, options: .transitionCrossDissolve) {
            keyWindow.overrideUserInterfaceStyle = newAppearance
        }
    }
}
