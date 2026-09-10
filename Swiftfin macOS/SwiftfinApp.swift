//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

@main
struct SwiftfinApp: App {

    @ObservedObject
    private var windowState = MacWindowState.shared

    init() {
        Self.configure()
    }

    var body: some Scene {
        WindowGroup("Swiftfin") {
            OverlayToastView {
                WithUserAuthentication {
                    RootView()
                }
            }
            // the Picture in Picture window is deliberately tiny, so the
            // browsing minimum would otherwise clamp it back to 900pt
            .frame(
                minWidth: windowState.isFloating ? 320 : 900,
                minHeight: windowState.isFloating ? 180 : 600
            )
        }
        .defaultSize(width: 1280, height: 820)
        .windowResizability(.contentMinSize)
        .windowToolbarStyle(.unified)
    }
}
