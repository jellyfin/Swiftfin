//
/*
 * SwiftFin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import Foundation
import SwiftUI
import Defaults

final class SettingsViewModel: ObservableObject {
    let currentLocale = Locale.current
    var bitrates: [Bitrates] = []
    var langs = [TrackLanguage]()
    let appearances = AppAppearance.allCases
    let videoPlayerJumpLengths = VideoPlayerJumpLength.allCases

    init() {
        let url = Bundle.main.url(forResource: "bitrates", withExtension: "json")!

        do {
            let jsonData = try Data(contentsOf: url, options: .mappedIfSafe)
            do {
                self.bitrates = try JSONDecoder().decode([Bitrates].self, from: jsonData)
            } catch {
                LogManager.shared.log.error("Error converting processed JSON into Swift compatible schema.")
            }
        } catch {
            LogManager.shared.log.error("Error processing JSON file `bitrates.json`")
        }

        self.langs = Locale.isoLanguageCodes.compactMap {
            guard let name = currentLocale.localizedString(forLanguageCode: $0) else { return nil }
            return TrackLanguage(name: name, isoCode: $0)
        }.sorted(by: { $0.name < $1.name })
        self.langs.insert(.auto, at: 0)
    }
}
