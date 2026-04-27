//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Factory
import Foundation
import JellyfinAPI

extension LogFile {

    var url: URL? {
        guard let name, let client = Container.shared.currentUserSession()?.client else { return nil }
        let request = Paths.getLogFile(name: name)
        return client.fullURL(with: request, queryAPIKey: true)
    }

    var type: ServerLogType {
        name.map(ServerLogType.init(rawValue:)) ?? .other
    }
}
