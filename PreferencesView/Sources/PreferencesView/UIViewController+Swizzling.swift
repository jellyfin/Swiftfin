//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import UIKit

extension UIViewController {

    // MARK: Swizzle

    static var swizzle = {
        #if os(iOS)
        _swizzle(
            #selector(getter: supportedInterfaceOrientations),
            #selector(swizzled_supportedInterfaceOrientations)
        )
        #endif
    }()

    private static func _swizzle(
        _ original: Selector,
        _ replacement: Selector
    ) {
        guard let a = class_getInstanceMethod(UIViewController.self, original),
              let b = class_getInstanceMethod(UIViewController.self, replacement)
        else { return }

        method_exchangeImplementations(a, b)
    }

    // MARK: Swizzles

    #if os(iOS)

    @objc
    func swizzled_supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        search()?._orientations ?? .all
    }

    #endif

    // MARK: Search

    private func search() -> UIPreferencesHostingController? {
        children.lazy.compactMap { $0 as? UIPreferencesHostingController }.first
            ?? children.lazy.compactMap { $0.search() }.first
    }
}
