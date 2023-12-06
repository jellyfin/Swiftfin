import SwizzleSwift
import UIKit

extension UIViewController {
    
    // MARK: Swizzle
    
    // only swizzle once
    static var swizzlePreferences = {
        Swizzle(UIViewController.self) {
            #selector(getter: childForScreenEdgesDeferringSystemGestures) <-> #selector(swizzled_childForScreenEdgesDeferringSystemGestures)
            #selector(getter: supportedInterfaceOrientations) <-> #selector(swizzled_supportedInterfaceOrientations)
//            #selector(getter: childForHomeIndicatorAutoHidden) <-> #selector(swizzled_childForHomeIndicatorAutoHidden)
//            #selector(getter: prefersHomeIndicatorAutoHidden) <-> #selector(swizzled_prefersHomeIndicatorAutoHidden)
        }
    }()
    
    // MARK: Swizzles
    
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
