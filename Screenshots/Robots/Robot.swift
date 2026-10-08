//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import XCTest

@MainActor
class Robot {

    let app: XCUIApplication

    init(app: XCUIApplication) {
        self.app = app
    }

    func button(_ label: String) -> XCUIElement {
        app.buttons[label].firstMatch
    }

    func buttons(containing text: String) -> XCUIElementQuery {
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", text))
    }

    func buttons(labeled label: String) -> XCUIElementQuery {
        app.buttons.matching(NSPredicate(format: "label == %@", label))
    }

    func largest(_ query: XCUIElementQuery) -> XCUIElement {
        waitFor(query.firstMatch)

        return query.allElementsBoundByIndex
            .max { $0.frame.width * $0.frame.height < $1.frame.width * $1.frame.height } ?? query.firstMatch
    }

    @discardableResult
    func waitFor(
        _ element: XCUIElement,
        timeout: TimeInterval = 20,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        XCTAssertTrue(
            element.waitForExistence(timeout: timeout),
            "Timed out waiting for \(element)",
            file: file,
            line: line
        )
        return element
    }

    func reveal(_ element: XCUIElement, maxAttempts: Int = 15) {
        for _ in 0 ..< maxAttempts {
            if element.exists {
                return
            }

            #if os(tvOS)
            XCUIRemote.shared.press(.down)
            #else
            app.swipeUp()
            #endif
        }
    }

    func tap(_ element: XCUIElement) {
        waitFor(element)

        #if os(tvOS)
        focus(element)
        XCUIRemote.shared.press(.select)
        #else
        element.tap()
        #endif
    }

    func type(_ text: String, into field: XCUIElement) {
        tap(field)
        app.typeText(text)

        #if os(tvOS)
        XCUIRemote.shared.press(.menu)
        #endif
    }

    func back() {
        #if os(tvOS)
        XCUIRemote.shared.press(.menu)
        sleep(2)
        #else
        tap(app.navigationBars.buttons.element(boundBy: 0))
        #endif
    }

    @discardableResult
    func screenshot(_ screenshot: Screenshot, waitForIdle: Bool = true) -> Self {
        #if os(tvOS)
        sleep(2)
        #endif

        snapshot(screenshot.rawValue, timeWaitingForIdle: waitForIdle ? 20 : 0)
        screenshot.saveCaption()
        return self
    }
}

#if os(tvOS)
extension Robot {

    var focusedElement: XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "hasFocus == true"))
            .firstMatch
    }

    func focus(_ element: XCUIElement, maxPresses: Int = 50) {
        var isStuck = false
        var lastWasVertical = false

        for _ in 0 ..< maxPresses {
            let current = focusedElement.frame
            let target = element.frame

            if element.hasFocus || current.contains(target) {
                return
            }

            let dx = target.midX - current.midX
            let dy = target.midY - current.midY
            let vertical: XCUIRemote.Button = dy > 0 ? .down : .up
            let horizontal: XCUIRemote.Button = dx > 0 ? .right : .left

            let useVertical = isStuck ? !lastWasVertical : abs(dy) > current.height / 2
            let direction = useVertical ? vertical : horizontal

            XCUIRemote.shared.press(direction)

            isStuck = focusedElement.frame == current
            lastWasVertical = useVertical
        }

        XCTFail(
            "Unable to focus \(element) at \(element.frame), focused: \(focusedElement.exists ? focusedElement.debugDescription : "nothing")"
        )
    }
}
#endif
