//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Factory
import Logging

extension Logger {

    static func swiftfin() -> Logger {
        Logger(label: "org.jellyfin.swiftfin")
    }
}

extension Container {

    @available(*, deprecated, message: "Use `Logger.swiftfin()` instances instead")
    var logService: Factory<Logger> {
        self {
            Logger(label: "org.jellyfin.swiftfin")
        }
        .unique
    }
}

struct SwiftfinConsoleHandler: LogHandler {

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
