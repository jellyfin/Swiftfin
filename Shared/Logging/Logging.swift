//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Factory
import Logging

extension Logger {

    static func swiftfin() -> Logger {
        Logger(label: "org.jellyfin.swiftfin")
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
        let line = "[\(level.emoji) \(level.rawValue.capitalized)] \(file.shortFileName)#\(line):\(function) \(message)"
        let meta = (metadata ?? [:]).merging(self.metadata) { _, new in new }
        let metadataString = meta.map { "\t- \($0): \($1)" }.joined(separator: "\n")

        print(line)

        if metadataString.isNotEmpty {
            print(metadataString)
        }
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
