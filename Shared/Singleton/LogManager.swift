//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Factory
import Foundation
import Puppy

class LogManager {

    static let service = Factory<Puppy>(scope: .singleton) {
        Puppy.swiftfinInstance()
    }

//    static let log = Puppy()
}

class LogFormatter: LogFormattable {
    func formatMessage(
        _ level: LogLevel,
        message: String,
        tag: String,
        function: String,
        file: String,
        line: UInt,
        swiftLogInfo: [String: String],
        label: String,
        date: Date,
        threadID: UInt64
    ) -> String {
        let file = shortFileName(file).replacingOccurrences(of: ".swift", with: "")
        return " [\(level.emoji) \(level)] \(file)#\(line):\(function) \(message)"
    }
}

private extension Puppy {
    static func swiftfinInstance() -> Puppy {

        let logger = Puppy()

        #if !os(tvOS)
        let logsDirectory = URL.documents.appendingPathComponent("logs", isDirectory: true)

        do {
            try FileManager.default.createDirectory(
                atPath: logsDirectory.path,
                withIntermediateDirectories: true,
                attributes: nil
            )
        } catch {
            // logs directory already created
        }

        let logFileURL = logsDirectory.appendingPathComponent("swiftfin_log.log")

        let fileRotationLogger = try! FileRotationLogger(
            "org.jellyfin.swiftfin.logger.file-rotation",
            fileURL: logFileURL
        )
        fileRotationLogger.format = LogFormatter()
        logger.add(fileRotationLogger, withLevel: .debug)
        #endif

        let consoleLogger = ConsoleLogger("org.jellyfin.swiftfin.logger.console")
        consoleLogger.format = LogFormatter()

        logger.add(consoleLogger, withLevel: .debug)
        return logger
    }
}
