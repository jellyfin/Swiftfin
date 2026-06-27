//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import SwiftUI

@main
struct SwiftfinApp: App {

    @StateObject
    private var valueObservation = ValueObservation()

    init() {
        Self.configure()

        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.label]
    }

    var body: some Scene {
        WindowGroup {
            OverlayToastView {
                WithUserAuthentication {
                    RootView()
                }
            }
            // Frame the whole app with the rotating SyncPlay border whenever we're in a Watch Together group.
            .syncPlayActiveBorder()
            // App-wide lower-left banners for Watch Together events (user/group join & leave). Non-interactive
            // overlay; renders nothing until an event arrives.
            .overlay {
                SyncPlayNotificationBanner()
            }
            // Keep the Apple TV Top Shelf fresh, but ONLY while the app is in use (the shelf is off-screen
            // then, so the reload is invisible). We deliberately do NOT publish on `.background`: doing so
            // rebuilt the shelf at the exact moment the user landed on the tvOS Home screen with the shelf
            // visible, causing a flicker. Publishing on `.active` (app opened / returned from background)
            // plus HomeView's first-appear and back-to-Home publishes keeps it current before the user ever
            // leaves, so exiting to Home shows an already-settled shelf.
            .onScenePhase(.active) { publishTopShelf() }
            // Rebuild the session-scoped plumbing (WebSocket / SyncPlay / socket observer) whenever the
            // signed-in user/server changes, so nothing stays bound to the previous server. Idempotent.
            .task { Container.shared.sessionPlumbingReset().begin() }
        }
    }

    /// Rebuilds the Top Shelf payload from the latest server data. Runs off the main work at background
    /// priority; the publisher itself clears the shelf when signed out, so it's safe to call any time.
    private func publishTopShelf() {
        Task(priority: .background) { @MainActor in
            await TopShelfPublisher().publish()
        }
    }
}
