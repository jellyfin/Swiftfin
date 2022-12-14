//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import UIKit

extension UIDevice {
    static var vendorUUIDString: String {
        current.identifierForVendor!.uuidString
    }

    static var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    static var isPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }

    static var platform: String {
        #if os(tvOS)
        "tvOS"
        #else
        "iOS"
        #endif
    }

    #if os(iOS)
    static var isPortrait: Bool {
        UIDevice.current.orientation.isPortrait
    }

    static var isLandscape: Bool {
        isIPad || UIDevice.current.orientation.isLandscape
    }

    static func feedback(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }

    static func impact(_ type: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: type).impactOccurred()
    }
    #endif
}
