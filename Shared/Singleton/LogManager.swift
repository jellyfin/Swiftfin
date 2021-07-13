//
 /* 
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import Foundation
import Puppy

final class LogManager {
    static let shared = LogManager()
    let log = Puppy()
    
    init() {
        let console = ConsoleLogger("me.vigue.jellyfin.ConsoleLogger")
        let fileURL = URL(fileURLWithPath: "./app.log").absoluteURL
        let file = try? FileLogger("me.vigue.jellyfin", fileURL: fileURL)
        console.format = LogFormatter();
        log.add(console, withLevel: .debug)
        if(file != nil) {
            file!.format = LogFormatter();
            log.add(file!, withLevel: .debug)
        }
    }
}

class LogFormatter: LogFormattable {
    func formatMessage(_ level: LogLevel, message: String, tag: String, function: String,
                       file: String, line: UInt, swiftLogInfo: [String : String],
                       label: String, date: Date, threadID: UInt64) -> String {
        let date = dateFormatter(date)
        let file = shortFileName(file)
        return "\(date) \(threadID) [\(level.emoji) \(level)] \(file)#L.\(line) \(function) \(message)"
    }
}
