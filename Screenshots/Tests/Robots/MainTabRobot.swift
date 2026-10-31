//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import XCTest

final class MainTabRobot: Robot {

    @discardableResult
    func home() -> Self {
        selectTab(L10n.home)
        return self
    }

    func media() -> LibraryRobot {
        selectTab(L10n.media)
        return LibraryRobot(app: app)
    }

    func search(_ query: String) -> LibraryRobot {
        selectTab(L10n.search)

        #if os(tvOS)
        // The search keyboard takes focus instead of the field.
        waitFor(app.searchFields.firstMatch)
        sleep(2)
        app.typeText(query)
        #else
        type(query + "\n", into: waitFor(app.searchFields.firstMatch))
        #endif

        sleep(3)

        return LibraryRobot(app: app)
    }

    func settings() -> SettingsRobot {
        #if os(iOS)
        home()
        tap(button(L10n.settings))
        #else
        selectTab(L10n.settings)
        #endif

        return SettingsRobot(app: app)
    }

    private func selectTab(_ name: String) {
        let tab = button(name)

        #if os(tvOS)
        if waitFor(tab).isSelected {
            return
        }

        sleep(2)

        for _ in 0 ..< 6 where tab.frame.width < 10 {
            XCUIRemote.shared.press(.menu)
            sleep(3) // wait for animations
        }
        #endif

        tap(tab)
    }
}
