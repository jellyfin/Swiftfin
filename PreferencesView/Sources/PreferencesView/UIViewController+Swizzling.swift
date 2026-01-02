//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwizzleSwift
import UIKit

extension UIViewController {

    // MARK: Swizzle

    // only swizzle once
    static var swizzlePreferences = {
        Swizzle(UIViewController.self) {
            #if os(iOS)
            #selector(getter: childForScreenEdgesDeferringSystemGestures) <-> #selector(swizzled_childForScreenEdgesDeferringSystemGestures)
            #selector(getter: supportedInterfaceOrientations) <-> #selector(swizzled_supportedInterfaceOrientations)
            #endif
        }
    }()

    // MARK: Swizzles

    #if os(iOS)

    @objc
    func swizzled_childForScreenEdgesDeferringSystemGestures() -> UIViewController? {
        if self is UIPreferencesHostingController {
            return nil
        } else {
            return search()
        }
    }

    @objc
    func swizzled_childForHomeIndicatorAutoHidden() -> UIViewController? {
        if self is UIPreferencesHostingController {
            return nil
        } else {
            return search()
        }
    }

    @objc
    func swizzled_prefersHomeIndicatorAutoHidden() -> Bool {
        search()?.prefersHomeIndicatorAutoHidden ?? false
    }

    @objc
    func swizzled_supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        search()?._orientations ?? .all
    }
    #endif

    // MARK: Search

    private func search() -> UIPreferencesHostingController? {
        if let result = children.compactMap({ $0 as? UIPreferencesHostingController }).first {
            return result
        }

        for child in children {
            if let result = child.search() {
                return result
            }
        }

        return nil
    }
}
