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

class LogManager {
    static let shared = LogManager()
    let log = Puppy()
    
    init() {
        let console = ConsoleLogger("me.vigue.jellyfin.ConsoleLogger")
        let fileURL = self.getDocumentsDirectory().appendingPathComponent("logs.txt")
        let FM = FileManager()
        _ = try? FM.removeItem(at: fileURL)
        
        do {
            let file = try FileLogger("me.vigue.jellyfin", fileURL: fileURL)
            file.format = LogFormatter();
            log.add(file, withLevel: .debug)
        } catch(let err) {
            log.error("Couldn't initialize file logger.")
            print(err);
        }
        console.format = LogFormatter();
        log.add(console, withLevel: .debug)
        log.info("Logger initialized.")
    }
    
    func logFileURL() -> URL {
        return self.getDocumentsDirectory().appendingPathComponent("logs.txt")
    }
    
    func getDocumentsDirectory() -> URL {
        // find all possible documents directories for this user
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)

        // just send back the first one, which ought to be the only one
        return paths[0]
    }
}

class LogFormatter: LogFormattable {
    func formatMessage(_ level: LogLevel, message: String, tag: String, function: String,
                       file: String, line: UInt, swiftLogInfo: [String : String],
                       label: String, date: Date, threadID: UInt64) -> String {
        let file = shortFileName(file).replacingOccurrences(of: ".swift", with: "")
        return " [\(level.emoji) \(level)] \(file)#\(line):\(function) \(message)"
    }
}
