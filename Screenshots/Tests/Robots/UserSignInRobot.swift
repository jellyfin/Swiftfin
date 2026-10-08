//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import XCTest

final class UserSignInRobot: Robot {

    func signIn(username: String, password: String) -> MainTabRobot {
        type(username, into: waitFor(app.textFields[L10n.username]))

        if password.isNotEmpty {
            type(password, into: app.secureTextFields[L10n.password])
        }

        tap(button(L10n.signIn))

        return MainTabRobot(app: app)
    }
}
