//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
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
            #if DEBUG
            // Bruno: render the GUI from mock data with no server/sign-in/keychain when
            // launched with `BRUNO_SNAPSHOT=1` (see BrunoPreviewSupport.swift). Inert otherwise.
            if ProcessInfo.processInfo.environment["BRUNO_SNAPSHOT"] == "1" {
                BrunoSnapshotGallery()
            } else if ProcessInfo.processInfo.environment["BRUNO_COLLECTION_PROBE"] != nil {
                BrunoCollectionProbe()
            } else {
                root
                    .task { await BrunoAutoSignIn.runIfRequested() }
            }
            #else
            root
            #endif
        }
    }

    @ViewBuilder
    private var root: some View {
        OverlayToastView {
            WithUserAuthentication {
                RootView()
            }
        }
        .brunoDebugOverlay()
    }
}
