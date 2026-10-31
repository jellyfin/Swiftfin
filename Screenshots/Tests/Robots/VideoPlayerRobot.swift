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
        button("closePlayerButton")
    }

    @discardableResult
    func showControls() -> Self {
        #if os(tvOS)
        XCUIRemote.shared.press(.select)
        sleep(1)
        #else
        let isHidden = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false OR isEnabled == false"),
            object: closeButton
        )
        _ = XCTWaiter().wait(for: [isHidden], timeout: 10)

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

        let remaining = waitFor(app.staticTexts["playbackRemainingTime"])
        let width = remaining.frame.maxX - (app.frame.width - remaining.frame.maxX)
        let start = app.coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: app.frame.midX, dy: remaining.frame.minY - 10))

        start.press(forDuration: 0.5, thenDragTo: start.withOffset(CGVector(dx: -width, dy: 0)))
        start.press(forDuration: 0.5, thenDragTo: start.withOffset(CGVector(dx: width * progress, dy: 0)))

        sleep(2)
        #else
        waitForControlsToHide()

        for _ in 0 ..< 200 {
            XCUIRemote.shared.press(.right)
            usleep(500_000)

            if let elapsed = elapsedProgress(), elapsed >= progress {
                break
            }
        }

        waitForControlsToHide()
        #endif

        return self
    }

    #if os(tvOS)
    func waitForPlayback() -> Bool {
        sleep(3)

        for _ in 0 ..< 20 {
            if !snapshotElements().contains(where: { $0.label == L10n.playerLoading }) {
                return true
            }

            sleep(1)
        }

        return false
    }

    // Presses act on the controls while they are up.
    private func waitForControlsToHide() {
        for _ in 0 ..< 15 where elapsedProgress() != nil {
            sleep(1)
        }
    }

    private func elapsedProgress() -> Double? {
        let elements = snapshotElements()

        guard let elapsed = elements.first(where: { $0.identifier == "playbackElapsedTime" }),
              let remaining = elements.first(where: { $0.identifier == "playbackRemainingTime" })
        else { return nil }

        let elapsedSeconds = seconds(elapsed.label)
        let totalSeconds = elapsedSeconds + seconds(remaining.label)

        return totalSeconds > 0 ? elapsedSeconds / totalSeconds : nil
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
    // Hidden controls stay in the hierarchy and are only disabled.
    private func revealControls() {
        for _ in 0 ..< 3 {
            if closeButton.exists, closeButton.isEnabled {
                return
            }

            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()

            let isEnabled = XCTNSPredicateExpectation(predicate: NSPredicate(format: "isEnabled == true"), object: closeButton)

            if XCTWaiter().wait(for: [isEnabled], timeout: 3) == .completed {
                return
            }
        }

        XCTFail("Unable to show player controls")
    }
    #endif
}
