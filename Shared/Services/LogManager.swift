//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import CoreStore
import Factory
import Foundation
import Logging
import Pulse

// TODO: cleanup
extension Container {
    var logService: Factory<Logger> { self { Logger(label: "org.jellyfin.swiftfin") }.singleton }

    var pulseNetworkLogger: Factory<NetworkLogger> {
        self {
            let configuration = NetworkLogger.Configuration()
            return NetworkLogger(configuration: configuration)
        }
        .singleton
    }
}

struct LogManager {
    // TODO: make rules for logging sessions and redacting

//    static let pulseNetworkLogger = Factory<NetworkLogger>(scope: .singleton) {
//        var configuration = NetworkLogger.Configuration()

    // TODO: this used to be necessary to stop the mass of image requests
    //       clogging the logs, however don't seem necessary anymore?
    //       Find out how to get images to be logged and have an option to
    //       turn it on, via SuperUser.

//        configuration.willHandleEvent = { event -> LoggerStore.Event? in
//            switch event {
//            case let .networkTaskCreated(networkTask):
//                if networkTask.originalRequest.url?.absoluteString.range(of: "/Images") != nil {
//                    return nil
//                }
//            case let .networkTaskCompleted(networkTask):
//                if networkTask.originalRequest.url?.absoluteString.range(of: "/Images") != nil {
//                    return nil
//                }
//            default: ()
//            }
//
//            return event
//        }

//        return NetworkLogger(configuration: configuration)
//    }
}

struct SwiftfinConsoleLogger: LogHandler {

    var logLevel: Logger.Level = .trace
    var metadata: Logger.Metadata = [:]

    subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get {
            metadata[key]
        }
        set(newValue) {
            metadata[key] = newValue
        }
    }

    func log(
        level: Logger.Level,
        message: Logger.Message,
        metadata: Logger.Metadata?,
        source: String,
        file: String,
        function: String,
        line: UInt
    ) {
        print("[\(level.emoji) \(level.rawValue.capitalized)] \(file.shortFileName)#\(line):\(function) \(message)")
    }
}

struct SwiftfinCorestoreLogger: CoreStoreLogger {

    @Injected(\.logService)
    private var logger

    func log(
        error: CoreStoreError,
        message: String,
        fileName: StaticString,
        lineNumber: Int,
        functionName: StaticString
    ) {
        logger.error(
            "\(message)",
            metadata: nil,
            source: "Corestore",
            file: fileName.description,
            function: functionName.description,
            line: UInt(lineNumber)
        )
    }

    func log(
        level: LogLevel,
        message: String,
        fileName: StaticString,
        lineNumber: Int,
        functionName: StaticString
    ) {
        logger.log(
            level: level.asSwiftLog,
            "\(message)",
            metadata: nil,
            source: "Corestore",
            file: fileName.description,
            function: functionName.description,
            line: UInt(lineNumber)
        )
    }

    func assert(
        _ condition: @autoclosure () -> Bool,
        message: @autoclosure () -> String,
        fileName: StaticString,
        lineNumber: Int,
        functionName: StaticString
    ) {}
}

extension Logger.Level {
    var emoji: String {
        switch self {
        case .trace:
            return "🟣"
        case .debug:
            return "🔵"
        case .info:
            return "🟢"
        case .notice:
            return "🟠"
        case .warning:
            return "🟡"
        case .error:
            return "🔴"
        case .critical:
            return "💥"
        }
    }
}
