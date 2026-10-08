//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

struct ScreenshotConfiguration {

    var server = "https://demo.jellyfin.org/stable"
    var username = "demo"
    var password = ""

    let movieLibrary = "Movies"
    let movie = "Caminandes: Llama Drama"

    let showLibrary = "Shows"
    let series = "Pioneer One"

    init(launchArguments: [String]) {
        func value(for key: String) -> String? {
            guard let index = launchArguments.firstIndex(of: "-\(key)") else { return nil }

            return launchArguments[safe: index + 1]?.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        }

        server = value(for: "ScreenshotServer") ?? server
        username = value(for: "ScreenshotUsername") ?? username
        password = value(for: "ScreenshotPassword") ?? password
    }
}
