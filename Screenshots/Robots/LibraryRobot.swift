//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import XCTest

final class LibraryRobot: Robot {

    func library(_ name: String) -> LibraryRobot {
        tap(largest(buttons(labeled: name)))
        return LibraryRobot(app: app)
    }

    func item(_ title: String) -> ItemRobot {
        let itemButton = button(title)
        reveal(itemButton)
        tap(itemButton)
        return ItemRobot(app: app)
    }

    func goBack() -> LibraryRobot {
        back()
        return LibraryRobot(app: app)
    }
}
