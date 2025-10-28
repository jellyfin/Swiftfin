//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import UIKit

extension UIDevice {

    static var vendorUUIDString: String {
        current.identifierForVendor!.uuidString
    }

    static var isPad: Bool {
        current.userInterfaceIdiom == .pad
    }

    static var isPhone: Bool {
        current.userInterfaceIdiom == .phone
    }

    static var isTV: Bool {
        current.userInterfaceIdiom == .tv
    }

    static var hasNotch: Bool {
        (UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0) > 0 &&
            isPhone
    }

    static var platform: String {
        #if os(tvOS)
        "tvOS"
        #else
        if UIDevice.isPad {
            return "iPadOS"
        } else {
            return "iOS"
        }
        #endif
    }

    /// - Important: Does nothing on non-iOS platforms.
    static func feedback(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        #if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(type)
        #endif
    }

    // TODO: make more custom feedback types with Core Haptics
    //       - soft with intensity
    /// - Important: Does nothing on non-iOS platforms.
    static func impact(_ type: UIImpactFeedbackGenerator.FeedbackStyle) {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: type).impactOccurred()
        #endif
    }

    #if os(iOS)
    static var isPortrait: Bool {
        current.orientation.isPortrait
    }

    static var isLandscape: Bool {
        isPad || current.orientation.isLandscape
    }
    #endif
}

#if os(tvOS)
enum UINotificationFeedbackGenerator {
    enum FeedbackType {
        case success
        case warning
        case error
    }
}

enum UIImpactFeedbackGenerator {
    enum FeedbackStyle {
        case light
        case medium
        case heavy
    }
}
#endif
