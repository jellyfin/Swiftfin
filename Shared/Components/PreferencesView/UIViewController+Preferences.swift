//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import UIKit

#if os(iOS)
extension UIViewController {

    static let forwardOrientationPreferences: Void = {
        swizzleInstanceMethod(
            #selector(getter: supportedInterfaceOrientations),
            with: #selector(preferencesSupportedInterfaceOrientations)
        )
    }()

    @objc
    private func preferencesSupportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        preferencesHostingController()?.supportedInterfaceOrientations ?? .all
    }

    private func preferencesHostingController() -> UIPreferencesHostingController? {
        children.lazy.compactMap { $0 as? UIPreferencesHostingController }.first
            ?? children.lazy.compactMap { $0.preferencesHostingController() }.first
    }
}
#endif
