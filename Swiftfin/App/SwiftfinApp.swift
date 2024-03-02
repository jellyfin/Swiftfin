//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import CoreStore
import Defaults
import Logging
import PreferencesView
import Pulse
import PulseLogHandler
import SwiftUI

@main
struct SwiftfinApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self)
    var appDelegate

    init() {

        // Defaults
        Task {
            for await newValue in Defaults.updates(.accentColor) {
                UIApplication.shared.setAccentColor(newValue.uiColor)
            }
        }

        Task {
            for await newValue in Defaults.updates(.appAppearance) {
                UIApplication.shared.setAppearance(newValue.style)
            }
        }

        // Logging
        LoggingSystem.bootstrap { label in

            var loggers: [LogHandler] = [PersistentLogHandler(label: label).withLogLevel(.trace)]

            #if DEBUG
            loggers.append(SwiftfinConsoleLogger())
            #endif

            return MultiplexLogHandler(loggers)
        }

        CoreStoreDefaults.dataStack = SwiftfinStore.dataStack
        CoreStoreDefaults.logger = SwiftfinCorestoreLogger()

        // Sometimes the tab bar won't appear properly on push, always have material background
        UITabBar.appearance().scrollEdgeAppearance = UITabBarAppearance(idiom: .unspecified)
    }

    var body: some Scene {
        WindowGroup {
            PreferencesView {
                MainCoordinator()
                    .view()
                    .supportedOrientations(UIDevice.isPad ? .allButUpsideDown : .portrait)
            }
            .ignoresSafeArea()
            .onOpenURL { url in
                AppURLHandler.shared.processDeepLink(url: url)
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
