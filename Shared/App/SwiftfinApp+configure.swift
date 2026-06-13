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
import PulseLogHandler
import UIKit

extension SwiftfinApp {

    static func configure() {

        #if DEBUG
        SwizzleDefaults.set(Defaults[.isLiquidGlassEnabled], for: "com.apple.SwiftUI.IgnoreSolariumOptOut")
        #endif

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

        _ = Container.shared.userSessionManager()
    }
}
