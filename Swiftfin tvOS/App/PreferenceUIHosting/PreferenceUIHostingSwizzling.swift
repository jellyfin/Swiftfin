//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

// TODO: IMPLEMENT BUTTON OVERRIDES IN `PreferencesView` PACKAGE

// import SwiftUI
// import SwizzleSwift
// import UIKit
//
//// MARK: - wrapper view
//
///// Wrapper view that will apply swizzling to make iOS query the child view for preference settings.
///// Used in combination with PreferenceUIHostingController.
/////
///// Source: https://gist.github.com/Amzd/01e1f69ecbc4c82c8586dcd292b1d30d
// struct PreferenceUIHostingControllerView<Wrapped: View>: UIViewControllerRepresentable {
//    init(@ViewBuilder wrappedView: @escaping () -> Wrapped) {
//        _ = UIViewController.preferenceSwizzling
//        self.wrappedView = wrappedView
//    }
//
//    var wrappedView: () -> Wrapped
//
//    func makeUIViewController(context: Context) -> PreferenceUIHostingController {
//        PreferenceUIHostingController { wrappedView() }
//    }
//
//    func updateUIViewController(_ uiViewController: PreferenceUIHostingController, context: Context) {}
// }
//
//// MARK: - swizzling uiviewcontroller extensions
//
// extension UIViewController {
//    static var preferenceSwizzling: Void = {
//        Swizzle(UIViewController.self) {
////            #selector(getter: childForScreenEdgesDeferringSystemGestures) <->
/// #selector(swizzled_childForScreenEdgesDeferringSystemGestures)
////            #selector(getter: childForHomeIndicatorAutoHidden) <-> #selector(swizzled_childForHomeIndicatorAutoHidden)
//        }
//    }()
// }
//
// extension UIViewController {
//    @objc
//    func swizzled_childForScreenEdgesDeferringSystemGestures() -> UIViewController? {
//        if self is PreferenceUIHostingController {
//            // dont continue searching
//            return nil
//        } else {
//            return search()
//        }
//    }
//
//    @objc
//    func swizzled_childForHomeIndicatorAutoHidden() -> UIViewController? {
//        if self is PreferenceUIHostingController {
//            // dont continue searching
//            return nil
//        } else {
//            return search()
//        }
//    }
//
//    private func search() -> PreferenceUIHostingController? {
//        if let result = children.compactMap({ $0 as? PreferenceUIHostingController }).first {
//            return result
//        }
//
//        for child in children {
//            if let result = child.search() {
//                return result
//            }
//        }
//
//        return nil
//    }
// }
