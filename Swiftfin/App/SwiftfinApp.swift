//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CoreStore
import Defaults
import Factory
import Logging
import Nuke
import PreferencesView
import PulseLogHandler
import SwiftUI

@main
struct SwiftfinApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self)
    var appDelegate

    @StateObject
    private var valueObservation = ValueObservation()

    init() {

        // Logging
        LoggingSystem.bootstrap { label in

            // TODO: have setting for log level
            //       - default info, boolean to go down to trace
            let handlers: [any LogHandler] = [PersistentLogHandler(label: label)]
            #if DEBUG
                .appending(SwiftfinConsoleHandler())
            #endif

            var multiplexHandler = MultiplexLogHandler(handlers)
            multiplexHandler.logLevel = .trace
            return multiplexHandler
        }

        // CoreStore

        CoreStoreDefaults.dataStack = SwiftfinStore.dataStack
        CoreStoreDefaults.logger = SwiftfinCorestoreLogger()

        // Nuke

        ImageCache.shared.costLimit = 1024 * 1024 * 200 // 200 MB
        ImageCache.shared.ttl = 300 // 5 min

        ImageDecoderRegistry.shared.register { context in
            guard let mimeType = context.urlResponse?.mimeType else { return nil }
            return mimeType.contains("svg") ? ImageDecoders.Empty() : nil
        }

        ImagePipeline.shared = .Swiftfin.posters

        // UIKit

        UIScrollView.appearance().keyboardDismissMode = .onDrag

        // Sometimes the tab bar won't appear properly on push, always have material background
        UITabBar.appearance().scrollEdgeAppearance = UITabBarAppearance(idiom: .unspecified)

        // Swiftfin

        // don't keep last user id
        if Defaults[.signOutOnClose] {
            Defaults[.lastSignedInUserID] = .signedOut
        }
    }

    var body: some Scene {
        WindowGroup {
            OverlayToastView {
                PreferencesView {
                    RootView()
                        .supportedOrientations(UIDevice.isPad ? .allButUpsideDown : .portrait)
                }
            }
            .ignoresSafeArea()
            .onAppDidEnterBackground {
                Defaults[.backgroundTimeStamp] = Date.now
            }
            .onAppWillEnterForeground {

                // TODO: needs to check if any background playback is happening
                //       - atow, background video playback isn't officially supported
                let backgroundedInterval = Date.now.timeIntervalSince(Defaults[.backgroundTimeStamp])

                if Defaults[.signOutOnBackground], backgroundedInterval > Defaults[.backgroundSignOutInterval] {
                    Defaults[.lastSignedInUserID] = .signedOut
                    Container.shared.currentUserSession.reset()
                    Notifications[.didSignOut].post()
                }
            }
        }
    }
}

extension UINavigationController {

    // Remove back button text
    override open func viewWillLayoutSubviews() {
        navigationBar.topItem?.backButtonDisplayMode = .minimal
    }
}

import ObjectiveC.runtime

private enum BundleInfoSwizzler {
    static func install() {
        guard let original1 = class_getInstanceMethod(Bundle.self, #selector(Bundle.object(forInfoDictionaryKey:))),
              let swizzled1 = class_getInstanceMethod(Bundle.self, #selector(Bundle._swizzled_object(forInfoDictionaryKey:))),
              let original2 = class_getInstanceMethod(Bundle.self, #selector(getter: Bundle.infoDictionary)),
              let swizzled2 = class_getInstanceMethod(Bundle.self, #selector(getter: Bundle._swizzled_infoDictionary))
        else {
            assertionFailure("Failed to find Bundle methods to swizzle")
            return
        }

        method_exchangeImplementations(original1, swizzled1)
        method_exchangeImplementations(original2, swizzled2)
    }
}

fileprivate extension Bundle {
    @objc
    func _swizzled_object(forInfoDictionaryKey key: String) -> Any? {
        if self == .main, key == "UIDesignRequiresCompatibility" {
            return true
        }

        // Because of swizzling, this actually calls the original implementation.
        return _swizzled_object(forInfoDictionaryKey: key)
    }

    @objc
    var _swizzled_infoDictionary: [String: Any]? {
        var dict = _swizzled_infoDictionary ?? [:] // original implementation
        if self == .main {
            dict["UIDesignRequiresCompatibility"] = true
        }
        return dict
    }
}
