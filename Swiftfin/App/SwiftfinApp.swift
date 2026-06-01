//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import PreferencesView
import SwiftUI
import UIKit

@main
struct SwiftfinApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self)
    private var appDelegate

    @StateObject
    private var valueObservation = ValueObservation()
    @StateObject
    private var sessionMessageObserver = SessionMessageObserver()

    init() {
        Self.configure()

        UIScrollView.appearance().keyboardDismissMode = .onDrag

        // Sometimes the tab bar won't appear properly on push, always have material background.
        UITabBar.appearance().scrollEdgeAppearance = UITabBarAppearance(idiom: .unspecified)

        SwiftfinSpotlight().addSwiftfinToSpotlight()
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
                sessionMessageObserver.stop()
            }
            .onAppWillEnterForeground {

                // TODO: needs to check if any background playback is happening
                //       - atow, background video playback isn't officially supported
                let backgroundedInterval = Date.now.timeIntervalSince(Defaults[.backgroundTimeStamp])

                if Defaults[.signOutOnBackground], backgroundedInterval > Defaults[.backgroundSignOutInterval] {
                    Defaults[.lastSignedInUserID] = .signedOut
                    Container.shared.currentUserSession.reset()
                    Notifications[.didSignOut].post()
                } else {
                    sessionMessageObserver.start()
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
