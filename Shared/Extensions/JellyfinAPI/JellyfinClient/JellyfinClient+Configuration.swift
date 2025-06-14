//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import UIKit

extension JellyfinClient.Configuration {

    static func swiftfinConfiguration(url: URL) -> Self {

        let client = "Swiftfin \(UIDevice.platform)"
        let deviceName = UIDevice.current.name
            .folding(options: .diacriticInsensitive, locale: .current)
            .unicodeScalars
            .filter { CharacterSet.urlQueryAllowed.contains($0) }
            .description
        let deviceID = "\(UIDevice.platform)_\(UIDevice.vendorUUIDString)"
        let version = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "0.0.1"

        return .init(
            url: url,
            client: client,
            deviceName: deviceName,
            deviceID: deviceID,
            version: version
        )
    }
}
