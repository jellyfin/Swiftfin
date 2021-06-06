/* JellyfinPlayer/Swiftfin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import Foundation

final class SettingsViewModel: ObservableObject {
    var bitrates: [Bitrates] = []

    init() {
        let url = Bundle.main.url(forResource: "bitrates", withExtension: "json")!

        do {
            let jsonData = try Data(contentsOf: url, options: .mappedIfSafe)
            do {
                self.bitrates = try JSONDecoder().decode([Bitrates].self, from: jsonData)
            } catch {
                print(error)
            }
        } catch {
            print(error)
        }
    }
}
