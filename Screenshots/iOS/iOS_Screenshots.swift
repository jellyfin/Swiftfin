//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import XCTest

final class iOS_Screenshots: XCTestCase {
    let demoServerUrl = "127.0.0.1:8096"
    let demoServerName = "Jellyfin Server"
    let demoUsername = "username"
    let demoPassword = "password"

    let movieTitle = "Sintel"

    let showTitle = "Pioneer One"
    let episodeTitle = "The Man From Mars"

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {}

    // Connect to the demo server from the ConnectToServer view
    func connectToDemoServer(_ app: XCUIApplication) {
        app.textFields["Server URL"].tap()
        app.typeText(demoServerUrl)
        app.buttons["ConnectToServer"].tap()
    }

    // Select/Add the demo server from the user selection view
    func selectDemoServer(_ app: XCUIApplication) {
        app.buttons["SelectServerMenu"].firstMatch.tap()

        if app.buttons["\(demoServerName)"].exists {
            app.buttons["\(demoServerName)"].firstMatch.tap()
        } else {
            app.buttons["Add Server"].firstMatch.tap()

            connectToDemoServer(app)
        }
    }

    // Select the demo user (or log in) from the user selection view
    func signInDemoUser(_ app: XCUIApplication) {
        if app.staticTexts[demoUsername].exists {
            app.staticTexts[demoUsername].firstMatch.tap()
        } else {
            app.buttons["Add User"].tap()

            app.typeText(demoUsername)
            app.secureTextFields["Password"].tap()
            app.typeText(demoPassword)

            app.buttons["Sign In"].tap()
        }
    }

    @MainActor
    func testScreenshots() throws {
        let app = XCUIApplication()

        setupSnapshot(app)
        app.launch()

        if UIDevice.current.userInterfaceIdiom == .pad {
            XCUIDevice.shared.orientation = .landscapeLeft
        }

        if app.buttons["Connect"].exists {
            app.buttons["ShowConnectToServer"].tap()
            connectToDemoServer(app)
        }

        if app.buttons["SelectServerMenu"].exists {
            selectDemoServer(app)
            signInDemoUser(app)

            sleep(2)
        }

        app.buttons["Settings"].firstMatch.tap()
        app.staticTexts["Server"].firstMatch.tap()
        if !app.staticTexts["http://\(demoServerUrl)"].exists {
            // Log out of this other server

            app.buttons["Settings"].tap()
            app.buttons["Switch User"].tap()

            selectDemoServer(app)
            signInDemoUser(app)

            sleep(2)
        } else {
            app.navigationBars["Server"]
                .buttons["Settings"].tap()
            app.buttons["NavigationBarClose"].tap()
        }

        snapshot("Home")

        let mediaTab = app.buttons["Media"].firstMatch

        mediaTab.tap()
        mediaTab.tap()

        snapshot("Media")

        app.buttons["Movies"].firstMatch.tap()

        snapshot("Movies")

        app.staticTexts[movieTitle].tap()
        app.images["play.fill"].tap()

        sleep(8)

        // TODO: There should be a better way to reveal the overlay
        app.buttons["Exit"].firstMatch.coordinate(withNormalizedOffset: .zero).tap()

        snapshot("PlaybackPortrait")

        app.buttons["Exit"].firstMatch.tap()

        app.images["play.fill"].tap()

        XCUIDevice.shared.orientation = .landscapeLeft

        sleep(8)

        app.buttons["Exit"].firstMatch.coordinate(withNormalizedOffset: .zero).tap()

        snapshot("Playback")

        XCUIDevice.shared.orientation = .portrait

        app.buttons["Exit"].firstMatch.tap()

        mediaTab.tap()
        mediaTab.tap()

        app.buttons["Shows"].tap()
        app.staticTexts[showTitle].tap()

        snapshot("Series")

        app.staticTexts[episodeTitle].tap()

        snapshot("Episode")
    }
}
