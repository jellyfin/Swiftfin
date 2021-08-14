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
    let logConstructor: LogConstructor

    var id: String {
        return "\(code)\(title)\(logConstructor.message)"
    }

    /// If the custom displayMessage is `nil`, it will be set to the given logConstructor's message
    init(code: Int, title: String, displayMessage: String?, logConstructor: LogConstructor) {
        self.code = code
        self.title = title
        self.displayMessage = displayMessage ?? logConstructor.message
        self.logConstructor = logConstructor
    }
}
