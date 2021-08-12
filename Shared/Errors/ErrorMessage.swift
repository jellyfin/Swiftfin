//
 /* 
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import Foundation
import JellyfinAPI

struct ErrorMessage: Identifiable {
    
    let code: Int
    let title: String
    let displayMessage: String
    let logMessage: String
    let logLevel: LogLevel
    let logTag: String
    
    var id: String {
        return "\(code)\(title)\(logMessage)"
    }
    
    /// If the given displayMessage is `nil`, it will be set to the given logMessage
    init(code: Int, title: String, displayMessage: String?, logMessage: String, logLevel: LogLevel, logTag: String?) {
        self.code = code
        self.title = title
        self.displayMessage = displayMessage ?? logMessage
        self.logMessage = logMessage
        self.logLevel = logLevel
        self.logTag = logTag ?? ""
    }
}
