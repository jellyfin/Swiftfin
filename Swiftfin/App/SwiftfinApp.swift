//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import CoreStore
import Defaults
import Factory
import Logging
import Nuke
import PreferencesView
import Pulse
import PulseLogHandler
import SwiftUI

@main
struct SwiftfinApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self)
    var appDelegate

    @StateObject
    private var valueObservation = ValueObservation()

    init() {

        // CoreStore

        CoreStoreDefaults.dataStack = SwiftfinStore.dataStack
        CoreStoreDefaults.logger = SwiftfinCorestoreLogger()

        // Logging
        LoggingSystem.bootstrap { label in

            var loggers: [LogHandler] = [PersistentLogHandler(label: label).withLogLevel(.trace)]

            #if DEBUG
            loggers.append(SwiftfinConsoleLogger())
            #endif

            return MultiplexLogHandler(loggers)
        }

        // Nuke

        ImageCache.shared.costLimit = 1024 * 1024 * 200 // 200 MB
        ImageCache.shared.ttl = 300 // 5 min

        ImageDecoderRegistry.shared.register { context in
            guard let mimeType = context.urlResponse?.mimeType else { return nil }
            return mimeType.contains("svg") ? ImageDecoders.Empty() : nil
        }

        ImagePipeline.shared = .Swiftfin.default

        // UIKit

        UIScrollView.appearance().keyboardDismissMode = .onDrag

        // Sometimes the tab bar won't appear properly on push, always have material background
        UITabBar.appearance().scrollEdgeAppearance = UITabBarAppearance(idiom: .unspecified)

        // Swiftfin

        // don't keep last user id
        if Defaults[.signOutOnClose] {
            Defaults[.lastSignedInUserID] = nil
        }
    }

    var body: some Scene {
        WindowGroup {
            PreferencesView {
                MainCoordinator()
                    .view()
                    .supportedOrientations(UIDevice.isPad ? .allButUpsideDown : .portrait)
            }
            .ignoresSafeArea()
            .onNotification(UIApplication.didEnterBackgroundNotification) { _ in
                Defaults[.backgroundTimeStamp] = Date.now
            }
            .onNotification(UIApplication.willEnterForegroundNotification) { _ in

                // TODO: needs to check if any background playback is happening
                //       - atow, background video playback isn't officially supported
                let backgroundedInterval = Date.now.timeIntervalSince(Defaults[.backgroundTimeStamp])

                if backgroundedInterval > Defaults[.backgroundSignOutInterval] {
                    Defaults[.lastSignedInUserID] = nil
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
