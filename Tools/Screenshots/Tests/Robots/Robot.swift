//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import XCTest

@MainActor
final class Robot {

    let app: XCUIApplication

    init(app: XCUIApplication) {
        self.app = app
    }

    var isDuo: Bool {
        app.launchArguments.contains("-captureDuo")
    }

    func button(_ label: String) -> XCUIElement {
        app.buttons[label].firstMatch
    }

    func buttons(containing text: String) -> XCUIElementQuery {
        buttons(matching: NSPredicate(format: "label CONTAINS %@", text))
    }

    func buttons(labeled label: String) -> XCUIElementQuery {
        buttons(matching: NSPredicate(format: "label == %@", label))
    }

    // Buttons with a context menu are exposed as pop up buttons.
    private func buttons(matching predicate: NSPredicate) -> XCUIElementQuery {
        app.descendants(matching: .any)
            .matching(NSPredicate(
                format: "elementType IN %@",
                [XCUIElement.ElementType.button, .popUpButton].map(\.rawValue)
            ))
            .matching(predicate)
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

    func goBack() -> Self {
        #if os(tvOS)
        XCUIRemote.shared.press(.menu)
        sleep(2)
        #else
        let back = button("BackButton")

        tap(back.exists ? back : app.navigationBars.buttons.element(boundBy: 0))
        #endif

        return self
    }

    @discardableResult
    func screenshotDetail(_ name: String, landscape: Bool = false) throws -> Self {
        guard isDuo else { return screenshot(name) }

        waitFor(button(L10n.play))

        let simulator = try XCTUnwrap(ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"])
        let folder = try XCTUnwrap(Snapshot.screenshotsDirectory)
        let png = folder.appendingPathComponent("\(simulator)-\(name).png")
        let request = png.appendingPathExtension("request")

        // The inner display sits a quarter turn from the cover. The host folds it back before acknowledging.
        try (landscape ? "portrait" : "landscape-left").write(to: request, atomically: true, encoding: .utf8)

        let finished = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            !FileManager.default.fileExists(atPath: request.path)
        }, object: nil)

        XCTAssertEqual(XCTWaiter.wait(for: [finished], timeout: 45), .completed, "Waiting for \(name) on the inner display")

        let image = try XCTUnwrap(UIImage(contentsOfFile: png.path)?.cgImage, "Inner capture failed for \(name)")

        XCTAssertEqual([image.width, image.height], landscape ? [2853, 2007] : [2007, 2853])

        return self
    }

    @discardableResult
    func screenshot(_ name: String, waitForIdle: Bool = true) -> Self {
        if waitForIdle {
            sleep(3)
        }

        snapshot(name, timeWaitingForIdle: waitForIdle ? 20 : 0)
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

    // Containers of the focused element also report focus, so take the innermost one.
    var focusedLabel: String? {
        snapshotElements().last(where: \.hasFocus)?.label
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

    func snapshotElements() -> [XCUIElementSnapshot] {
        guard let root = try? app.snapshot() else { return [] }

        return flattened(root)
    }

    private func flattened(_ snapshot: XCUIElementSnapshot) -> [XCUIElementSnapshot] {
        [snapshot] + snapshot.children.flatMap(flattened)
    }
}
#endif
