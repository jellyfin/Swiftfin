//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import XCTest

final class tvOS_Screenshots: XCTestCase {
    let demoServerUrl = "127.0.0.1:8096"
    let demoServerName = "Jellyfin Server"
    let demoUsername = "username"
    let demoPassword = "password"

    let movieTitle = "Sintel"

    let showTitle = "Pioneer One"
    let episodeTitle = "The Man From Mars"

    let app = XCUIApplication()
    let remote = XCUIRemote.shared

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run.
        // The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func connectToDemoServer() {
        // Start with "Connect" Selected
        press(.select)
        app.typeText(demoServerUrl)

        // Navigate to "done" button
        press(.down, times: 5)
        press(.select)

        // Press connect
        press(.down)
        press(.select)
    }

    func selectDemoServer() {
        // Navigate to server select menu
        press(.down, times: 3)
        press(.right, times: 3)
        press(.left)

        press(.select)

        // Make sure we're at the top of the server list
        press(.up, times: 5)

        // Using the server name is necessary since the text with the URL isn't accessible for some reason
        search(repeating: .down) {
            app.focused.buttons[demoServerName].exists
                || app.focused.buttons["Add Server"].exists
        }

        var needAddServer = app.focused.buttons["Add Server"].exists

        press(.select)

        if needAddServer {
            connectToDemoServer()
        }
    }

    func signInDemoUser() {
        // Assuming we've already selected the demo server, focus on the user button
        press(.up, times: 2)

        _ = app.focused.waitForExistence(timeout: 5)

        if app.focused.staticTexts["Add User"].exists {
            press(.select)

            // Select username, type, and hit "next"
            press(.select)
            app.typeText(demoUsername)
            press(.down, times: 4)
            press(.select)

            // Select password, type, and hit "done"
            app.typeText(demoPassword)
            press(.down, times: 4)
            press(.select)
        } else {
            press(.select)
        }
    }

    @MainActor
    func testScreenshots() throws {
        // UI tests must launch the application that they test.
        setupSnapshot(app)
        app.launch()

        if app.staticTexts["Connect to a Jellyfin server to get started"].exists {
            // Press "Connect"
            press(.select)
            connectToDemoServer()
        }

        if app.images["server.rack"].exists {
            selectDemoServer()
            signInDemoUser()

            sleep(2)
        }

        // Go to settings and inspect the server
        press(.right, times: 5)
        press(.select)
        press(.down)
        press(.select)

        let onDemoServer = app.staticTexts["http://\(demoServerUrl)"].exists

        // Go back up to settings
        press(.menu)

        if !onDemoServer {
            // Go to "Switch User"
            press(.down)
            press(.select)

            selectDemoServer()
            signInDemoUser()
        }

        // Go home
        press(.up, times: 3)
        press(.left, times: 5)
        press(.select)
        press(.up)
        sleep(2)

        snapshot("Home")

        press(.right)
        sleep(2)

        snapshot("Shows")

        press(.right)
        sleep(2)

        snapshot("Movies")

        press(.select)

        press(.left, times: 5)
        search(repeating: .right) {
            app.focused.staticTexts[movieTitle].exists
        }

        press(.select)

        snapshot("Movie")

        // Press play
        press(.select)
        sleep(5)
        snapshot("Playback")

        // Exit playback, wait, exit to Movies view
        press(.menu, times: 2, wait: false)
        _ = app.focused.waitForExistence(timeout: 5)
        press(.menu)

        // Go to TV
        press(.up)
        press(.left)
        press(.select)

        search(repeating: .right) {
            app.focused.staticTexts[showTitle].exists
        }

        press(.select)

        snapshot("Series")

        // Go down from Play, to action buttons, to season selector, to thumbnail, to description
        press(.down, times: 4)
        // The second episode
        press(.right)
        press(.select)

        snapshot("Episode")
    }

    func press(_ remoteButton: XCUIRemote.Button, times: Int = 1, wait: Bool? = nil) {
        for _ in 0 ..< times {
            remote.press(remoteButton)

            // It often takes a bit for the cursor to reappear after moving between views
            if wait ?? (remoteButton == .select || remoteButton == .menu) {
                _ = app.focused.waitForExistence(timeout: 5)
            }
        }
    }

    func search(repeating: XCUIRemote.Button, condition: () -> Bool) {
        var prevDetails = ""

        while !condition() {
            press(repeating)
            _ = app.focused.waitForExistence(timeout: 1)

            let thisDetail = app.focused.details
            if thisDetail == prevDetails {
                XCTFail("Search failed")
            }
            prevDetails = thisDetail
        }
    }
}

extension XCUIApplication {
    var focused: XCUIElement {
        descendants(matching: .any)
            .element(matching: NSPredicate(format: "hasFocus == true"))
    }
}

extension XCUIElement {
    var details: String {
        // Remove instances of " 0x123...," since these addresses change moment to moment
        let pattern = /\ 0x\S+/
        return debugDescription.replacing(pattern, with: "")
    }
}
