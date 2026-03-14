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
import Pulse
import PulseLogHandler
import SwiftUI

@main
struct SwiftfinApp: App {

    init() {

        // Logging
        LoggingSystem.bootstrap { label in

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

        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.label]

        // don't keep last user id
        if Defaults[.signOutOnClose] {
            Defaults[.lastSignedInUserID] = .signedOut
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .onNotification(.applicationDidEnterBackground) {
                    Defaults[.backgroundTimeStamp] = Date.now
                }
                .onNotification(.applicationWillEnterForeground) {
                    // TODO: needs to check if any background playback is happening
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
