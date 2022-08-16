//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

final class BasicAppSettingsViewModel: ViewModel {

    let appearances = AppAppearance.allCases

    func resetUserSettings() {
        UserDefaults.generalSuite.removeAll()
    }

    func resetAppSettings() {
        UserDefaults.universalSuite.removeAll()
    }

    func removeAllUsers() {
        SessionManager.main.purge()
    }
}
