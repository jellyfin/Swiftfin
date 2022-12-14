//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import CoreStore
import Factory
import Foundation
import Logging

class LogManager {

    static let service = Factory<Logger>(scope: .singleton) {
        .init(label: "Swiftfin")
    }
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

    @Injected(LogManager.service)
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

extension CoreStore.LogLevel {
    var asSwiftLog: Logger.Level {
        switch self {
        case .trace:
            return .trace
        case .notice:
            return .debug
        case .warning:
            return .warning
        case .fatal:
            return .critical
        }
    }
}
