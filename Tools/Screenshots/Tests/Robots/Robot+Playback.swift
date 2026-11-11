//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import XCTest

extension Robot {

    func play() -> Self {
        let playButtons = buttons(labeled: L10n.play)

        waitFor(playButtons.firstMatch)

        #if os(tvOS)
        for _ in 0 ..< 5 where focusedLabel != L10n.play {
            XCUIRemote.shared.press(.up)
            sleep(1)
        }

        // Playback can stall on its first load, so back out and start it again.
        for _ in 0 ..< 3 {
            XCUIRemote.shared.press(.select)

            if waitForPlayback() {
                break
            }

            XCUIRemote.shared.press(.menu)
            sleep(3)

            if focusedLabel != L10n.play {
                XCUIRemote.shared.press(.menu)
                sleep(3)
            }
        }
        #else
        tap(playButtons.firstMatch)
        #endif

        return self
    }

    func preparePlayback(at progress: Double) -> Self {
        #if os(iOS)
        let close = waitFor(button("closePlayerButton"))
        let play = button(L10n.play)
        let pause = button(L10n.pause)
        let deadline = Date().addingTimeInterval(60)

        while !(play.exists && play.isEnabled && play.isHittable) {
            guard Date() < deadline else {
                XCTFail("Playback did not become ready to pause")
                return self
            }

            if pause.exists, pause.isEnabled, pause.isHittable {
                pause.tap()
            } else if !close.exists || !close.isEnabled || !close.isHittable {
                // The player keeps hidden controls in the accessibility tree.
                app.coordinate(withNormalizedOffset: CGVector(dx: 0.25, dy: 0.3)).tap()
            }

            sleep(1)
        }

        tap(button(L10n.aspectFill))

        let remaining = waitFor(app.staticTexts["playbackRemainingTime"])
        let right = remaining.frame.maxX
        let left = app.frame.width - right
        let width = right - left

        for _ in 0 ..< 3 {
            if let current = elapsedProgress() {
                let delta = progress - current

                if abs(delta) < 0.01 {
                    return self
                }

                // The slider uses relative motion. Keep both ends of the drag on the timeline.
                let start = app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(
                    dx: delta > 0 ? left + 2 : right - 2,
                    dy: remaining.frame.minY - 10
                ))

                start.press(forDuration: 0.3, thenDragTo: start.withOffset(CGVector(dx: width * delta, dy: 0)))
            }

            sleep(1)
        }

        XCTAssertEqual(elapsedProgress() ?? -1, progress, accuracy: 0.01, "Playback did not seek to the screenshot scene")
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
        XCUIRemote.shared.press(.select)
        sleep(1)
        #endif

        return self
    }

    #if os(tvOS)
    private func waitForPlayback() -> Bool {
        sleep(3)

        for _ in 0 ..< 20 {
            if !snapshotElements().contains(where: { $0.label == L10n.playerLoading }) {
                return true
            }

            sleep(1)
        }

        return false
    }

    /// Presses act on the controls while they are up.
    private func waitForControlsToHide() {
        for _ in 0 ..< 15 where elapsedProgress() != nil {
            sleep(1)
        }
    }
    #endif

    private func elapsedProgress() -> Double? {
        #if os(tvOS)
        let elements = snapshotElements()

        guard let elapsed = elements.first(where: { $0.identifier == "playbackElapsedTime" }),
              let remaining = elements.first(where: { $0.identifier == "playbackRemainingTime" })
        else { return nil }

        #else
        let elapsed = app.staticTexts["playbackElapsedTime"].firstMatch
        let remaining = app.staticTexts["playbackRemainingTime"].firstMatch

        guard elapsed.exists, remaining.exists else { return nil }

        #endif

        let elapsedSeconds = seconds(elapsed.label)
        let totalSeconds = elapsedSeconds + seconds(remaining.label)

        return totalSeconds > 0 ? elapsedSeconds / totalSeconds : nil
    }

    private func seconds(_ timestamp: String) -> Double {
        timestamp
            .trimmingPrefix("-")
            .trimmingPrefix("−")
            .split(separator: ":")
            .compactMap { Double($0) }
            .reduce(0) { $0 * 60 + $1 }
    }
}
