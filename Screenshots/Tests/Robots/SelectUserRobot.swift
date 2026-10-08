//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import XCTest

final class SelectUserRobot: Robot {

    func connect() -> ConnectToServerRobot {
        tap(button(L10n.connect))
        return ConnectToServerRobot(app: app)
    }

    func addUser() -> UserSignInRobot {
        tap(largest(buttons(containing: L10n.addUser)))
        return UserSignInRobot(app: app)
    }
}
