//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import XCTest

final class VideoPlayerRobot: Robot {

    private var closeButton: XCUIElement {
        button(L10n.close)
    }

    @discardableResult
    func showControls() -> Self {
        #if os(tvOS)
        XCUIRemote.shared.press(.select)
        sleep(1)
        #else
        revealControls()
        #endif

        return self
    }

    @discardableResult
    func aspectFill() -> Self {
        #if os(iOS)
        revealControls()
        button(L10n.aspectFill).tap()
        sleep(1)
        #endif

        return self
    }

    @discardableResult
    func scrub(toProgress progress: Double) -> Self {
        #if os(iOS)
        revealControls()

        let remaining = waitFor(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH '-'")).firstMatch)
        let width = remaining.frame.maxX - (app.frame.width - remaining.frame.maxX)
        let start = app.coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: app.frame.midX, dy: remaining.frame.minY - 10))

        start.press(forDuration: 0.5, thenDragTo: start.withOffset(CGVector(dx: -width, dy: 0)))
        start.press(forDuration: 0.5, thenDragTo: start.withOffset(CGVector(dx: width * progress, dy: 0)))

        sleep(2)
        #else
        for _ in 0 ..< 200 {
            XCUIRemote.shared.press(.right)
            usleep(500_000)

            if let elapsed = elapsedProgress(), elapsed >= progress {
                break
            }
        }

        sleep(2)
        #endif

        return self
    }

    #if os(tvOS)
    private func elapsedProgress() -> Double? {
        guard let root = try? app.snapshot() else { return nil }

        let texts = staticTexts(in: root)

        guard let remaining = texts.first(where: { $0.label.hasPrefix("-") }),
              let elapsed = texts
                  .filter({ abs($0.frame.midY - remaining.frame.midY) < 5 && $0.frame.maxX < remaining.frame.minX })
                  .min(by: { $0.frame.minX < $1.frame.minX })
        else { return nil }

        let elapsedSeconds = seconds(elapsed.label)
        let totalSeconds = elapsedSeconds + seconds(remaining.label)

        return totalSeconds > 0 ? elapsedSeconds / totalSeconds : nil
    }

    private func staticTexts(in snapshot: XCUIElementSnapshot) -> [XCUIElementSnapshot] {
        (snapshot.elementType == .staticText ? [snapshot] : []) + snapshot.children.flatMap(staticTexts)
    }

    private func seconds(_ timestamp: String) -> Double {
        timestamp
            .trimmingPrefix("-")
            .split(separator: ":")
            .compactMap { Double($0) }
            .reduce(0) { $0 * 60 + $1 }
    }
    #endif

    #if os(iOS)
    private func revealControls() {
        for _ in 0 ..< 3 {
            if closeButton.exists, closeButton.isHittable {
                return
            }

            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()

            let isHittable = XCTNSPredicateExpectation(predicate: NSPredicate(format: "isHittable == true"), object: closeButton)

            if XCTWaiter().wait(for: [isHittable], timeout: 3) == .completed {
                return
            }
        }

        XCTFail("Unable to show player controls")
    }
    #endif
}
