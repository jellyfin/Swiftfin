//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import CoreStore
import Foundation
import Logging

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
