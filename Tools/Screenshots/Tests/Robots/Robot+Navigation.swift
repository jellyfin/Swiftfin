//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import XCTest

extension Robot {

    func signIn(to server: String, username: String) {
        tap(button(L10n.connect))

        let field = waitFor(app.textFields[L10n.url])

        type(server, into: field)

        // Two Connect buttons can remain visible. Submit the one nearest the URL field.
        let center = CGPoint(x: field.frame.midX, y: field.frame.midY)

        func distance(_ element: XCUIElement) -> CGFloat {
            let frame = element.frame

            return hypot(frame.midX - center.x, frame.midY - center.y)
        }

        guard let connect = buttons(labeled: L10n.connect).allElementsBoundByIndex.min(by: { distance($0) < distance($1) }) else {
            XCTFail("Missing Connect button beside the server URL")
            return
        }

        tap(connect)
        tap(largest(buttons(containing: L10n.addUser)))
        type(username, into: waitFor(app.textFields[L10n.username]))

        #if os(iOS)
        if UIDevice.isPad {
            // The software keyboard moves the iPad sign-in sheet. Submit from the password field.
            type("\n", into: waitFor(app.secureTextFields[L10n.password]))
            return
        }
        #endif

        tap(button(L10n.signIn))
    }

    @discardableResult
    func home() -> Self {
        selectTab(L10n.home)
        return self
    }

    func media() -> Self {
        selectTab(L10n.media)
        return self
    }

    func library(_ name: String) -> Self {
        tap(largest(buttons(labeled: name)))
        return self
    }

    func item(_ title: String) -> Self {
        let item = buttons(containing: title).firstMatch

        reveal(item)
        tap(item)
        return self
    }

    func switchUser() -> Self {
        #if os(iOS)
        home()
        tap(button(L10n.settings))
        #else
        selectTab(L10n.settings)
        #endif

        tap(button(L10n.switchUser))
        return self
    }

    private func selectTab(_ name: String) {
        #if os(tvOS)
        let tab = button(name)

        if waitFor(tab).isSelected {
            return
        }

        sleep(2)

        for _ in 0 ..< 6 where tab.frame.width < 10 {
            // The tab bar animates into place after a Menu press.
            XCUIRemote.shared.press(.menu)
            sleep(3)
        }
        #else
        let tab = UIDevice.isPad ? app.cells[name].firstMatch : button(name)
        #endif

        tap(tab)
    }
}
